-- A Twitter-style @handle, distinct from the free-text display `name` —
-- unique (case-insensitively), shown (with the profile photo) wherever a
-- user's identity appears in the community feed.

alter table public.profiles add column if not exists username text;

create unique index if not exists profiles_username_unique_idx
  on public.profiles (lower(username))
  where username is not null;

create or replace view public.public_profiles as
  select id, name, profile_image, followers_count, following_count, username
  from public.profiles;

grant select on public.public_profiles to authenticated, anon;
