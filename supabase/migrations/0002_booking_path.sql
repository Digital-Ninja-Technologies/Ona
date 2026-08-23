-- TravelGuide Stage 2 schema: attractions, bookings, saved_destinations.
-- Apply with `supabase db push` (or paste into the SQL editor) after 0001_init.sql.

-- ---------------------------------------------------------------------------
-- attractions
-- ---------------------------------------------------------------------------
create table if not exists public.attractions (
  id uuid primary key default gen_random_uuid(),
  destination_id uuid not null references public.destinations (id) on delete cascade,
  name text not null,
  image_url text,
  description text,
  rating numeric(2, 1),
  created_at timestamptz not null default now()
);

alter table public.attractions enable row level security;

create policy "attractions are publicly readable" on public.attractions
  for select using (true);

-- ---------------------------------------------------------------------------
-- bookings
-- ---------------------------------------------------------------------------
create table if not exists public.bookings (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  experience_id uuid not null references public.experiences (id) on delete cascade,
  booking_date date not null,
  num_participants integer not null default 1,
  total_price numeric(10, 2) not null,
  commission_amount numeric(10, 2) not null,
  status text not null default 'pending',
  created_at timestamptz not null default now()
);

alter table public.bookings enable row level security;

create policy "bookings are readable by owner" on public.bookings
  for select using (auth.uid() = user_id);

create policy "bookings are insertable by owner" on public.bookings
  for insert with check (auth.uid() = user_id);

create or replace function public.handle_new_booking()
returns trigger
language plpgsql
security definer set search_path = public
as $$
begin
  update public.experiences
  set total_bookings = total_bookings + 1
  where id = new.experience_id;
  return new;
end;
$$;

drop trigger if exists on_booking_created on public.bookings;
create trigger on_booking_created
  after insert on public.bookings
  for each row execute procedure public.handle_new_booking();

-- ---------------------------------------------------------------------------
-- saved_destinations
-- ---------------------------------------------------------------------------
create table if not exists public.saved_destinations (
  user_id uuid not null references auth.users (id) on delete cascade,
  destination_id uuid not null references public.destinations (id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (user_id, destination_id)
);

alter table public.saved_destinations enable row level security;

create policy "saved_destinations are readable by owner" on public.saved_destinations
  for select using (auth.uid() = user_id);

create policy "saved_destinations are insertable by owner" on public.saved_destinations
  for insert with check (auth.uid() = user_id);

create policy "saved_destinations are deletable by owner" on public.saved_destinations
  for delete using (auth.uid() = user_id);

-- ---------------------------------------------------------------------------
-- seed attractions for the Stage 1 sample destinations
-- ---------------------------------------------------------------------------
insert into public.attractions (destination_id, name, image_url, description, rating)
select id, 'Fushimi Inari Shrine', 'https://images.unsplash.com/photo-1478436127897-769e1b3f0f36', 'Thousands of vermilion torii gates winding up the mountain.', 4.8
from public.destinations where name = 'Kyoto'
union all
select id, 'Arashiyama Bamboo Grove', 'https://images.unsplash.com/photo-1553913861-c0fddf2619ee', 'A towering, otherworldly bamboo forest path.', 4.6
from public.destinations where name = 'Kyoto'
union all
select id, 'Oia Sunset Point', 'https://images.unsplash.com/photo-1533105079780-92b9be482077', 'The classic caldera-view sunset spot.', 4.9
from public.destinations where name = 'Santorini'
union all
select id, 'Red Beach', 'https://images.unsplash.com/photo-1601581875039-e899893d520c', 'Volcanic red cliffs meeting the Aegean.', 4.4
from public.destinations where name = 'Santorini'
union all
select id, 'Jemaa el-Fnaa', 'https://images.unsplash.com/photo-1548013146-72479768bada', 'The main square and marketplace, alive after dark.', 4.5
from public.destinations where name = 'Marrakech'
union all
select id, 'Majorelle Garden', 'https://images.unsplash.com/photo-1553603227-2358aabe821e', 'A vivid cobalt-blue botanical garden.', 4.7
from public.destinations where name = 'Marrakech'
union all
select id, 'Milford Sound', 'https://images.unsplash.com/photo-1469521669194-babb45599def', 'Fiordland''s dramatic peaks and waterfalls.', 4.9
from public.destinations where name = 'Queenstown'
union all
select id, 'Skyline Gondola', 'https://images.unsplash.com/photo-1589871173980-5c353e5f4a08', 'Panoramic views over Lake Wakatipu.', 4.6
from public.destinations where name = 'Queenstown'
on conflict do nothing;
