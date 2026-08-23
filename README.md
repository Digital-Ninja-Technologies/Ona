# Ona

Flutter rewrite of the TravelGuide app (now Ona), backed by Supabase. This replaces the
previous Expo/React Native + Hono API codebase — see `git log` for the
original source if you need to reference it.

This covers **Stage 1 + Stage 2** of an incremental migration:

- **Stage 1**: project foundation — onboarding/auth flow, the six-tab
  navigation shell, and a real Home/Search vertical slice against Supabase.
- **Stage 2**: the core booking path — destination/experience detail pages,
  booking flow + confirmation, and a wishlist (saved destinations).

Itinerary creation/AI generation, travel agents, community, messaging, the
AI assistant, payments, and the remaining utility screens are still
"Coming soon" placeholders, landing in later stages.

## Prerequisites

- Flutter 3.44+ (`flutter --version`)
- A Supabase project (free tier is fine)

## 1. Create the Supabase project

Create a project at [supabase.com](https://supabase.com) (or via the
Supabase CLI/MCP tooling if you have it connected). Then apply the schema,
in order:

```bash
# Using the Supabase CLI, from the repo root:
supabase link --project-ref <your-project-ref>
supabase db push
```

Or paste the contents of `supabase/migrations/0001_init.sql` and then
`supabase/migrations/0002_booking_path.sql` into the SQL editor in the
Supabase dashboard, in that order:

- `0001_init.sql` creates `profiles`, `destinations`, `experiences`, sets up
  row-level security, wires an `auth.users` insert trigger to auto-create
  profiles, and seeds a handful of sample destinations so Home/Search have
  real data.
- `0002_booking_path.sql` creates `attractions`, `bookings`, and
  `saved_destinations`, with RLS scoping bookings/saves to their owner and a
  trigger that increments `experiences.total_bookings` on each new booking.
  Seeds a couple of attractions per Stage 1 sample destination.

In **Authentication → Providers**, email/password sign-up should already be
enabled by default.

## 2. Configure the app with your project credentials

Find your project URL and publishable (anon) key in
**Project Settings → API** in the Supabase dashboard, then run:

```bash
flutter run \
  --dart-define=SUPABASE_URL=https://<your-project-ref>.supabase.co \
  --dart-define=SUPABASE_PUBLISHABLE_KEY=<your-publishable-key>
```

Without these, the app shows a "Supabase is not configured" screen instead
of crashing.

To avoid retyping these every run, put them in a
`--dart-define-from-file=env.json` file (gitignored) instead — see
[the Flutter docs](https://docs.flutter.dev/deployment/flavors).

## Verifying it works

1. `flutter analyze` and `flutter test` should both pass.
2. `flutter run` (with the dart-defines above) → walk onboarding → sign up
   → land on the Home tab → confirm the seeded destinations/experiences
   render → use Search → confirm results → check all six bottom tabs are
   reachable.
3. Tap a destination → detail page renders with attractions; tap the heart
   to save it, then check Profile → Wishlist shows it and removing it there
   deletes it.
4. From Home, tap an experience → Book Now → pick a date, adjust
   participants, confirm → lands on a booking confirmation screen.
5. In the Supabase dashboard, confirm: the new auth user has a matching row
   in `profiles`; the booking created a row in `bookings` and incremented
   the linked `experiences.total_bookings`; the saved destination has a row
   in `saved_destinations`.

## Project structure

```
lib/
  core/
    config/    Supabase credentials (via --dart-define)
    data/      Repositories/providers for Supabase-backed data
    models/    Plain Dart data classes
    router/    go_router configuration
    theme/     Colors, text styles
    widgets/   Shared widgets (destination card, "coming soon" screen)
  features/
    auth/          Sign in, sign up, forgot password
    onboarding/     Welcome, interests
    home/           Home tab
    search/         Search (reached from Home, not a bottom tab)
    destination/    Destination detail
    experience/      Experience detail
    booking/        Booking flow + confirmation
    wishlist/        Saved destinations
    agents/         Agents tab (placeholder)
    itineraries/    Itineraries tab (placeholder)
    messages/       Messages tab (placeholder)
    community/      Community tab (placeholder)
    profile/        Profile tab (real: user info, wishlist link, sign out)
    shell/          Bottom-tab shell
supabase/
  migrations/    SQL schema + seed data (apply in numeric order)
```
