# Ona

Flutter rewrite of the TravelGuide app (now Ona), backed by Supabase. This replaces the
previous Expo/React Native + Hono API codebase — see `git log` for the
original source if you need to reference it.

This is **Stage 1** of an incremental migration: project foundation, the
onboarding/auth flow, the six-tab navigation shell, and a real Home/Search
vertical slice against Supabase. Booking, itinerary creation/AI generation,
travel agents, community, messaging, the AI assistant, payments, and the
remaining utility screens are stubbed with "Coming soon" placeholders and
land in later stages.

## Prerequisites

- Flutter 3.44+ (`flutter --version`)
- A Supabase project (free tier is fine)

## 1. Create the Supabase project

Create a project at [supabase.com](https://supabase.com) (or via the
Supabase CLI/MCP tooling if you have it connected). Then apply the schema:

```bash
# Using the Supabase CLI, from the repo root:
supabase link --project-ref <your-project-ref>
supabase db push
```

Or paste the contents of `supabase/migrations/0001_init.sql` into the SQL
editor in the Supabase dashboard. This creates `profiles`, `destinations`,
`experiences`, sets up row-level security, wires an `auth.users` insert
trigger to auto-create profiles, and seeds a handful of sample destinations
so Home/Search have real data.

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
3. In the Supabase dashboard, confirm the new auth user has a matching row
   in `profiles`.

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
    agents/         Agents tab (placeholder)
    itineraries/    Itineraries tab (placeholder)
    messages/       Messages tab (placeholder)
    community/      Community tab (placeholder)
    profile/        Profile tab (real: user info, sign out)
    shell/          Bottom-tab shell
supabase/
  migrations/    SQL schema + seed data
```
