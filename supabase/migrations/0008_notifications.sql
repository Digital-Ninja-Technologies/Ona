-- In-app notification center: a follow, like, comment/reply, repost, or
-- quote against your own content creates a row here. Rows are written only
-- by triggers (security definer), never directly by clients — RLS grants
-- select/update to the recipient but no insert policy at all, so a client
-- can't forge a notification "from" someone else.

create table if not exists public.notifications (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  actor_id uuid not null references auth.users (id) on delete cascade,
  type text not null check (type in ('follow', 'like', 'comment', 'repost', 'quote')),
  post_id uuid references public.community_posts (id) on delete cascade,
  comment_id uuid references public.post_comments (id) on delete cascade,
  read boolean not null default false,
  created_at timestamptz not null default now()
);

create index if not exists notifications_user_idx
  on public.notifications (user_id, created_at desc);

alter table public.notifications enable row level security;

create policy "notifications are readable by recipient" on public.notifications
  for select using (auth.uid() = user_id);

create policy "notifications are updatable by recipient" on public.notifications
  for update using (auth.uid() = user_id);

-- follow
create or replace function public.handle_new_follow_notification()
returns trigger
language plpgsql
security definer set search_path = public
as $$
begin
  insert into public.notifications (user_id, actor_id, type)
  values (new.followed_id, new.follower_id, 'follow');
  return new;
end;
$$;

drop trigger if exists on_follow_notify on public.follows;
create trigger on_follow_notify
  after insert on public.follows
  for each row execute procedure public.handle_new_follow_notification();

-- like
create or replace function public.handle_new_like_notification()
returns trigger
language plpgsql
security definer set search_path = public
as $$
declare
  post_owner uuid;
begin
  select user_id into post_owner from public.community_posts where id = new.post_id;
  if post_owner is not null and post_owner <> new.user_id then
    insert into public.notifications (user_id, actor_id, type, post_id)
    values (post_owner, new.user_id, 'like', new.post_id);
  end if;
  return new;
end;
$$;

drop trigger if exists on_like_notify on public.post_likes;
create trigger on_like_notify
  after insert on public.post_likes
  for each row execute procedure public.handle_new_like_notification();

-- comment (and reply, to the parent comment's author too)
create or replace function public.handle_new_comment_notification()
returns trigger
language plpgsql
security definer set search_path = public
as $$
declare
  post_owner uuid;
  parent_author uuid;
begin
  select user_id into post_owner from public.community_posts where id = new.post_id;
  if post_owner is not null and post_owner <> new.user_id then
    insert into public.notifications (user_id, actor_id, type, post_id, comment_id)
    values (post_owner, new.user_id, 'comment', new.post_id, new.id);
  end if;

  if new.parent_comment_id is not null then
    select user_id into parent_author from public.post_comments where id = new.parent_comment_id;
    if parent_author is not null
      and parent_author <> new.user_id
      and parent_author <> post_owner then
      insert into public.notifications (user_id, actor_id, type, post_id, comment_id)
      values (parent_author, new.user_id, 'comment', new.post_id, new.id);
    end if;
  end if;
  return new;
end;
$$;

drop trigger if exists on_comment_notify on public.post_comments;
create trigger on_comment_notify
  after insert on public.post_comments
  for each row execute procedure public.handle_new_comment_notification();

-- repost
create or replace function public.handle_new_repost_notification()
returns trigger
language plpgsql
security definer set search_path = public
as $$
declare
  post_owner uuid;
begin
  select user_id into post_owner from public.community_posts where id = new.post_id;
  if post_owner is not null and post_owner <> new.user_id then
    insert into public.notifications (user_id, actor_id, type, post_id)
    values (post_owner, new.user_id, 'repost', new.post_id);
  end if;
  return new;
end;
$$;

drop trigger if exists on_repost_notify on public.post_reposts;
create trigger on_repost_notify
  after insert on public.post_reposts
  for each row execute procedure public.handle_new_repost_notification();

-- quote-repost — fires on every new post, but only notifies when
-- quoted_post_id is set (a genuine quote of someone else's post).
create or replace function public.handle_new_quote_notification()
returns trigger
language plpgsql
security definer set search_path = public
as $$
declare
  quoted_owner uuid;
begin
  if new.quoted_post_id is not null then
    select user_id into quoted_owner from public.community_posts where id = new.quoted_post_id;
    if quoted_owner is not null and quoted_owner <> new.user_id then
      insert into public.notifications (user_id, actor_id, type, post_id)
      values (quoted_owner, new.user_id, 'quote', new.id);
    end if;
  end if;
  return new;
end;
$$;

drop trigger if exists on_quote_notify on public.community_posts;
create trigger on_quote_notify
  after insert on public.community_posts
  for each row execute procedure public.handle_new_quote_notification();
