-- TravelGuide Stage 1 schema: profiles, destinations, experiences.
-- Apply with `supabase db push` (or paste into the SQL editor) against a real Supabase project.

create extension if not exists "pgcrypto";

-- ---------------------------------------------------------------------------
-- profiles: one row per auth.users row, created automatically via trigger.
-- Replaces the old dual auth_users/users sync-on-write pattern.
-- ---------------------------------------------------------------------------
create table if not exists public.profiles (
  id uuid primary key references auth.users (id) on delete cascade,
  email text not null,
  name text,
  profile_image text,
  preferred_destinations text[] not null default '{}',
  budget_range text,
  interests text[] not null default '{}',
  language_preference text,
  is_premium boolean not null default false,
  premium_tier text,
  premium_expires_at timestamptz,
  created_at timestamptz not null default now()
);

alter table public.profiles enable row level security;

create policy "profiles are readable by owner" on public.profiles
  for select using (auth.uid() = id);

create policy "profiles are updatable by owner" on public.profiles
  for update using (auth.uid() = id);

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer set search_path = public
as $$
begin
  insert into public.profiles (id, email)
  values (new.id, new.email);
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();

-- ---------------------------------------------------------------------------
-- destinations
-- ---------------------------------------------------------------------------
create table if not exists public.destinations (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  country text not null,
  city text,
  destination_type text,
  description text,
  image_url text,
  latitude double precision,
  longitude double precision,
  category text[] not null default '{}',
  rating numeric(2, 1),
  price_range text,
  best_time_to_visit text,
  popular_activities text[] not null default '{}',
  created_at timestamptz not null default now()
);

alter table public.destinations enable row level security;

create policy "destinations are publicly readable" on public.destinations
  for select using (true);

-- ---------------------------------------------------------------------------
-- experiences
-- ---------------------------------------------------------------------------
create table if not exists public.experiences (
  id uuid primary key default gen_random_uuid(),
  destination_id uuid references public.destinations (id) on delete cascade,
  vendor_id uuid references auth.users (id),
  title text not null,
  description text,
  image_url text,
  category text,
  price numeric(10, 2) not null default 0,
  duration_hours numeric(5, 1),
  max_participants integer,
  rating numeric(2, 1),
  total_bookings integer not null default 0,
  is_approved boolean not null default true,
  created_at timestamptz not null default now()
);

alter table public.experiences enable row level security;

create policy "experiences are publicly readable" on public.experiences
  for select using (is_approved = true);

-- ---------------------------------------------------------------------------
-- seed data so Home/Search have something real to render
-- ---------------------------------------------------------------------------
insert into public.destinations (name, country, city, description, image_url, category, rating, price_range, best_time_to_visit, popular_activities)
values
  ('Kyoto', 'Japan', 'Kyoto', 'Historic temples, gardens, and geisha districts.', 'https://images.unsplash.com/photo-1493976040374-85c8e12f0c0e', array['culture', 'history'], 4.8, '$$', 'March–May, October–November', array['Fushimi Inari', 'Arashiyama Bamboo Grove', 'Tea ceremony']),
  ('Santorini', 'Greece', 'Thira', 'Whitewashed villages perched over the Aegean caldera.', 'https://images.unsplash.com/photo-1570077188670-e3a8d69ac5ff', array['beach', 'romance'], 4.7, '$$$', 'May–September', array['Sunset in Oia', 'Wine tasting', 'Caldera boat tour']),
  ('Marrakech', 'Morocco', 'Marrakech', 'Souks, palaces, and the Atlas Mountains nearby.', 'https://images.unsplash.com/photo-1597212720158-3b4e5c4d6f6a', array['culture', 'adventure'], 4.5, '$', 'March–May, September–November', array['Jemaa el-Fnaa', 'Majorelle Garden', 'Desert day trip']),
  ('Queenstown', 'New Zealand', 'Queenstown', 'Adventure capital on the shores of Lake Wakatipu.', 'https://images.unsplash.com/photo-1589871173980-5c353e5f4a08', array['adventure', 'nature'], 4.9, '$$$', 'December–February', array['Bungy jumping', 'Milford Sound', 'Skyline gondola'])
on conflict do nothing;

insert into public.experiences (destination_id, title, description, image_url, category, price, duration_hours, max_participants, rating)
select id, 'Guided walking tour', 'A local guide walks you through the highlights.', image_url, 'tour', 45.00, 3, 12, 4.6
from public.destinations
on conflict do nothing;
