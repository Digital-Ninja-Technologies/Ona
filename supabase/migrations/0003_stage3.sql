-- Stage 3 schema: travel agents, messaging, community, itineraries, reviews,
-- a public-profile view for showing names/avatars across those features, a
-- shared storage bucket for user-uploaded images, and mock-payment tracking
-- on bookings. Apply after 0001_init.sql and 0002_booking_path.sql.

-- ---------------------------------------------------------------------------
-- a minimal, publicly-readable slice of profiles (no email/preferences) so
-- community posts, comments, conversations, and chat can show a name/avatar
-- without exposing the rest of a user's profile.
-- ---------------------------------------------------------------------------
create or replace view public.public_profiles as
  select id, name, profile_image from public.profiles;

grant select on public.public_profiles to authenticated, anon;

-- ---------------------------------------------------------------------------
-- travel_agents
-- ---------------------------------------------------------------------------
create table if not exists public.travel_agents (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users (id) on delete set null,
  business_name text not null,
  bio text,
  specialties text[] not null default '{}',
  languages text[] not null default '{}',
  years_experience integer,
  rating numeric(2, 1),
  is_verified boolean not null default false,
  image_url text,
  created_at timestamptz not null default now()
);

alter table public.travel_agents enable row level security;

create policy "travel_agents are publicly readable" on public.travel_agents
  for select using (true);

-- ---------------------------------------------------------------------------
-- conversations + messages
-- ---------------------------------------------------------------------------
create table if not exists public.conversations (
  id uuid primary key default gen_random_uuid(),
  user1_id uuid not null references auth.users (id) on delete cascade,
  user2_id uuid not null references auth.users (id) on delete cascade,
  created_at timestamptz not null default now(),
  constraint conversations_distinct_users check (user1_id <> user2_id)
);

create index if not exists conversations_user1_idx on public.conversations (user1_id);
create index if not exists conversations_user2_idx on public.conversations (user2_id);

alter table public.conversations enable row level security;

create policy "conversations are readable by participants" on public.conversations
  for select using (auth.uid() = user1_id or auth.uid() = user2_id);

create policy "conversations are insertable by participants" on public.conversations
  for insert with check (auth.uid() = user1_id or auth.uid() = user2_id);

create table if not exists public.messages (
  id uuid primary key default gen_random_uuid(),
  conversation_id uuid not null references public.conversations (id) on delete cascade,
  sender_id uuid not null references auth.users (id) on delete cascade,
  content text not null,
  created_at timestamptz not null default now()
);

create index if not exists messages_conversation_idx on public.messages (conversation_id, created_at);

alter table public.messages enable row level security;

create policy "messages are readable by conversation participants" on public.messages
  for select using (
    exists (
      select 1 from public.conversations c
      where c.id = conversation_id
        and (c.user1_id = auth.uid() or c.user2_id = auth.uid())
    )
  );

create policy "messages are insertable by conversation participants" on public.messages
  for insert with check (
    sender_id = auth.uid()
    and exists (
      select 1 from public.conversations c
      where c.id = conversation_id
        and (c.user1_id = auth.uid() or c.user2_id = auth.uid())
    )
  );

-- ---------------------------------------------------------------------------
-- community_posts + likes + comments
-- ---------------------------------------------------------------------------
create table if not exists public.community_posts (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  type text not null default 'story' check (type in ('story', 'tip', 'question')),
  content text not null,
  image_url text,
  destination_id uuid references public.destinations (id) on delete set null,
  likes_count integer not null default 0,
  comments_count integer not null default 0,
  created_at timestamptz not null default now()
);

alter table public.community_posts enable row level security;

create policy "community_posts are publicly readable" on public.community_posts
  for select using (true);

create policy "community_posts are insertable by owner" on public.community_posts
  for insert with check (auth.uid() = user_id);

create policy "community_posts are deletable by owner" on public.community_posts
  for delete using (auth.uid() = user_id);

create table if not exists public.post_likes (
  post_id uuid not null references public.community_posts (id) on delete cascade,
  user_id uuid not null references auth.users (id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (post_id, user_id)
);

alter table public.post_likes enable row level security;

create policy "post_likes are publicly readable" on public.post_likes
  for select using (true);

create policy "post_likes are insertable by owner" on public.post_likes
  for insert with check (auth.uid() = user_id);

create policy "post_likes are deletable by owner" on public.post_likes
  for delete using (auth.uid() = user_id);

create or replace function public.handle_post_like_change()
returns trigger
language plpgsql
security definer set search_path = public
as $$
begin
  if tg_op = 'INSERT' then
    update public.community_posts set likes_count = likes_count + 1 where id = new.post_id;
    return new;
  else
    update public.community_posts set likes_count = greatest(likes_count - 1, 0) where id = old.post_id;
    return old;
  end if;
end;
$$;

drop trigger if exists on_post_like_change on public.post_likes;
create trigger on_post_like_change
  after insert or delete on public.post_likes
  for each row execute procedure public.handle_post_like_change();

create table if not exists public.post_comments (
  id uuid primary key default gen_random_uuid(),
  post_id uuid not null references public.community_posts (id) on delete cascade,
  user_id uuid not null references auth.users (id) on delete cascade,
  content text not null,
  created_at timestamptz not null default now()
);

create index if not exists post_comments_post_idx on public.post_comments (post_id, created_at);

alter table public.post_comments enable row level security;

create policy "post_comments are publicly readable" on public.post_comments
  for select using (true);

create policy "post_comments are insertable by owner" on public.post_comments
  for insert with check (auth.uid() = user_id);

create or replace function public.handle_post_comment_change()
returns trigger
language plpgsql
security definer set search_path = public
as $$
begin
  if tg_op = 'INSERT' then
    update public.community_posts set comments_count = comments_count + 1 where id = new.post_id;
    return new;
  else
    update public.community_posts set comments_count = greatest(comments_count - 1, 0) where id = old.post_id;
    return old;
  end if;
end;
$$;

drop trigger if exists on_post_comment_change on public.post_comments;
create trigger on_post_comment_change
  after insert or delete on public.post_comments
  for each row execute procedure public.handle_post_comment_change();

-- ---------------------------------------------------------------------------
-- itineraries (manual or AI-generated, owned by a single user)
-- ---------------------------------------------------------------------------
create table if not exists public.itineraries (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  title text not null,
  description text,
  destination_id uuid references public.destinations (id) on delete set null,
  destination_name text,
  duration_days integer not null default 1,
  budget text,
  is_ai_generated boolean not null default false,
  days jsonb not null default '[]'::jsonb,
  created_at timestamptz not null default now()
);

alter table public.itineraries enable row level security;

create policy "itineraries are readable by owner" on public.itineraries
  for select using (auth.uid() = user_id);

create policy "itineraries are insertable by owner" on public.itineraries
  for insert with check (auth.uid() = user_id);

create policy "itineraries are updatable by owner" on public.itineraries
  for update using (auth.uid() = user_id);

create policy "itineraries are deletable by owner" on public.itineraries
  for delete using (auth.uid() = user_id);

-- ---------------------------------------------------------------------------
-- reviews (exactly one of destination_id / experience_id / agent_id)
-- ---------------------------------------------------------------------------
create table if not exists public.reviews (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  destination_id uuid references public.destinations (id) on delete cascade,
  experience_id uuid references public.experiences (id) on delete cascade,
  agent_id uuid references public.travel_agents (id) on delete cascade,
  rating integer not null check (rating between 1 and 5),
  comment text not null,
  images text[] not null default '{}',
  created_at timestamptz not null default now(),
  constraint reviews_single_target check (
    num_nonnulls(destination_id, experience_id, agent_id) = 1
  )
);

create index if not exists reviews_destination_idx on public.reviews (destination_id);
create index if not exists reviews_experience_idx on public.reviews (experience_id);
create index if not exists reviews_agent_idx on public.reviews (agent_id);

alter table public.reviews enable row level security;

create policy "reviews are publicly readable" on public.reviews
  for select using (true);

create policy "reviews are insertable by owner" on public.reviews
  for insert with check (auth.uid() = user_id);

create policy "reviews are deletable by owner" on public.reviews
  for delete using (auth.uid() = user_id);

create or replace function public.handle_review_change()
returns trigger
language plpgsql
security definer set search_path = public
as $$
declare
  target_row public.reviews;
begin
  if tg_op = 'DELETE' then
    target_row := old;
  else
    target_row := new;
  end if;
  if target_row.destination_id is not null then
    update public.destinations set rating = (
      select round(avg(rating)::numeric, 1) from public.reviews where destination_id = target_row.destination_id
    ) where id = target_row.destination_id;
  elsif target_row.experience_id is not null then
    update public.experiences set rating = (
      select round(avg(rating)::numeric, 1) from public.reviews where experience_id = target_row.experience_id
    ) where id = target_row.experience_id;
  elsif target_row.agent_id is not null then
    update public.travel_agents set rating = (
      select round(avg(rating)::numeric, 1) from public.reviews where agent_id = target_row.agent_id
    ) where id = target_row.agent_id;
  end if;
  return target_row;
end;
$$;

drop trigger if exists on_review_change on public.reviews;
create trigger on_review_change
  after insert or delete on public.reviews
  for each row execute procedure public.handle_review_change();

-- ---------------------------------------------------------------------------
-- mock payment tracking on bookings (no real payment gateway is wired up)
-- ---------------------------------------------------------------------------
alter table public.bookings
  add column if not exists payment_status text not null default 'pending'
    check (payment_status in ('pending', 'paid', 'failed'));

-- ---------------------------------------------------------------------------
-- shared storage bucket for review photos / community post images
-- ---------------------------------------------------------------------------
insert into storage.buckets (id, name, public)
values ('uploads', 'uploads', true)
on conflict (id) do nothing;

create policy "uploads are publicly readable" on storage.objects
  for select using (bucket_id = 'uploads');

create policy "authenticated users can upload" on storage.objects
  for insert to authenticated with check (bucket_id = 'uploads');

create policy "owners can delete their uploads" on storage.objects
  for delete to authenticated using (bucket_id = 'uploads' and owner = auth.uid());

-- ---------------------------------------------------------------------------
-- seed a handful of travel agents (not linked to a user, so chat is hidden
-- for them until a real agent account signs up and claims the profile)
-- ---------------------------------------------------------------------------
insert into public.travel_agents (business_name, bio, specialties, languages, years_experience, rating, is_verified, image_url)
values
  ('Wanderlust Japan Tours', 'Kyoto-based guide specializing in cultural immersion trips across Japan.', array['culture', 'food', 'temples'], array['English', 'Japanese'], 8, 4.9, true, 'https://images.unsplash.com/photo-1528360983277-13d401cdc186'),
  ('Aegean Escapes', 'Boutique trip planning for the Greek islands, from Santorini to Crete.', array['beach', 'romance', 'sailing'], array['English', 'Greek'], 6, 4.7, true, 'https://images.unsplash.com/photo-1533105079780-92b9be482077'),
  ('Atlas Adventures', 'Morocco specialist covering the Sahara, the Atlas Mountains, and the medinas.', array['adventure', 'culture', 'desert'], array['English', 'French', 'Arabic'], 10, 4.8, true, 'https://images.unsplash.com/photo-1489493887464-892be6d1daae'),
  ('Southern Alps Expeditions', 'Adventure travel across New Zealand''s South Island.', array['adventure', 'hiking', 'nature'], array['English'], 5, 4.9, false, 'https://images.unsplash.com/photo-1469521669194-babb45599def')
on conflict do nothing;
