-- X/Twitter-style social graph: following other users, and reposting a
-- community post. Follows a public read + owner write/delete pattern, and
-- denormalized counts + triggers, matching post_likes/post_comments above.

-- ---------------------------------------------------------------------------
-- follows
-- ---------------------------------------------------------------------------
create table if not exists public.follows (
  follower_id uuid not null references auth.users (id) on delete cascade,
  followed_id uuid not null references auth.users (id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (follower_id, followed_id),
  constraint follows_no_self_follow check (follower_id <> followed_id)
);

create index if not exists follows_followed_idx on public.follows (followed_id);
create index if not exists follows_follower_idx on public.follows (follower_id);

alter table public.follows enable row level security;

-- Public, like Twitter's follow graph — needed to show "does A follow B" and
-- follower/following lists for any profile, not just your own.
create policy "follows are publicly readable" on public.follows
  for select using (true);

create policy "follows are insertable by follower" on public.follows
  for insert with check (auth.uid() = follower_id);

create policy "follows are deletable by follower" on public.follows
  for delete using (auth.uid() = follower_id);

alter table public.profiles add column if not exists followers_count integer not null default 0;
alter table public.profiles add column if not exists following_count integer not null default 0;

create or replace function public.handle_follow_change()
returns trigger
language plpgsql
security definer set search_path = public
as $$
begin
  if tg_op = 'INSERT' then
    update public.profiles set following_count = following_count + 1 where id = new.follower_id;
    update public.profiles set followers_count = followers_count + 1 where id = new.followed_id;
    return new;
  else
    update public.profiles set following_count = greatest(following_count - 1, 0) where id = old.follower_id;
    update public.profiles set followers_count = greatest(followers_count - 1, 0) where id = old.followed_id;
    return old;
  end if;
end;
$$;

drop trigger if exists on_follow_change on public.follows;
create trigger on_follow_change
  after insert or delete on public.follows
  for each row execute procedure public.handle_follow_change();

-- Re-expose the new counts through the public-profile view.
create or replace view public.public_profiles as
  select id, name, profile_image, followers_count, following_count
  from public.profiles;

grant select on public.public_profiles to authenticated, anon;

-- ---------------------------------------------------------------------------
-- post_reposts ("retweet")
-- ---------------------------------------------------------------------------
create table if not exists public.post_reposts (
  post_id uuid not null references public.community_posts (id) on delete cascade,
  user_id uuid not null references auth.users (id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (post_id, user_id)
);

alter table public.community_posts add column if not exists reposts_count integer not null default 0;

alter table public.post_reposts enable row level security;

create policy "post_reposts are publicly readable" on public.post_reposts
  for select using (true);

create policy "post_reposts are insertable by owner" on public.post_reposts
  for insert with check (auth.uid() = user_id);

create policy "post_reposts are deletable by owner" on public.post_reposts
  for delete using (auth.uid() = user_id);

create or replace function public.handle_post_repost_change()
returns trigger
language plpgsql
security definer set search_path = public
as $$
begin
  if tg_op = 'INSERT' then
    update public.community_posts set reposts_count = reposts_count + 1 where id = new.post_id;
    return new;
  else
    update public.community_posts set reposts_count = greatest(reposts_count - 1, 0) where id = old.post_id;
    return old;
  end if;
end;
$$;

drop trigger if exists on_post_repost_change on public.post_reposts;
create trigger on_post_repost_change
  after insert or delete on public.post_reposts
  for each row execute procedure public.handle_post_repost_change();
