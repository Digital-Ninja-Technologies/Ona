# Ona

Flutter rewrite of the TravelGuide app (now Ona), backed by Supabase. This replaces the
previous Expo/React Native + Hono API codebase — see `git log` for the
original source if you need to reference it.

This covers the full migration, **Stage 1 through Stage 3**:

- **Stage 1**: project foundation — onboarding/auth flow, the six-tab
  navigation shell, and a real Home/Search vertical slice against Supabase.
- **Stage 2**: the core booking path — destination/experience detail pages,
  booking flow + confirmation, and a wishlist (saved destinations).
- **Stage 3**: everything else — travel agents, messaging/chat, the
  community feed, itineraries (manual and AI-generated), an AI travel
  assistant, reviews (destinations/experiences/agents), a simulated payment
  step in the booking flow, and offline travel-essentials tools (currency
  converter, packing checklist, cultural etiquette, safety tips, emergency
  contacts).
- **Stage 4**: the Ọ̀nà brand redesign — the official palette (Deep Green,
  Route Green, Sand, Cream, Charcoal, Way Gold), Space Grotesk/Outfit
  typography, a Material 3 nav bar, the real logo/mark throughout the app,
  rebranded app icons + launch screens on both platforms, and an animated
  video splash screen (the brand's logo-build animation) as the app's first
  frame. See `assets/brand/` and `lib/core/theme/`.

No screen is a placeholder anymore. Two features call out to external
services and need extra setup beyond the Supabase schema — see
[AI features](#4-optional-ai-features-assistant--itinerary-generation) below:

- The **AI assistant** and **AI-generated itineraries** call a Supabase Edge
  Function that proxies to the Anthropic API. Without a deployed function +
  `ANTHROPIC_API_KEY` secret, those two entry points show an error instead of
  a response — everything else in the app works without them.
- The **booking payment step** is a simulated card form (validates input,
  "charges" nothing, always succeeds) since no real payment gateway is
  configured. Swap it for `flutter_stripe` + a real Edge Function if you want
  actual charges.

## Prerequisites

- Flutter 3.44+ (`flutter --version`)
- A Supabase project (free tier is fine)
- (Optional, for the AI assistant / AI itineraries) An Anthropic API key and
  the [Supabase CLI](https://supabase.com/docs/guides/cli) to deploy Edge
  Functions

## 1. Create the Supabase project

Create a project at [supabase.com](https://supabase.com) (or via the
Supabase CLI/MCP tooling if you have it connected). Then apply the schema,
in order:

```bash
# Using the Supabase CLI, from the repo root:
supabase link --project-ref <your-project-ref>
supabase db push
```

Or paste the contents of each file in `supabase/migrations/` into the SQL
editor in the Supabase dashboard, **in numeric order**:

- `0001_init.sql` creates `profiles`, `destinations`, `experiences`, sets up
  row-level security, wires an `auth.users` insert trigger to auto-create
  profiles, and seeds a handful of sample destinations so Home/Search have
  real data.
- `0002_booking_path.sql` creates `attractions`, `bookings`, and
  `saved_destinations`, with RLS scoping bookings/saves to their owner and a
  trigger that increments `experiences.total_bookings` on each new booking.
  Seeds a couple of attractions per Stage 1 sample destination.
- `0003_stage3.sql` creates `travel_agents`, `conversations`/`messages`,
  `community_posts`/`post_likes`/`post_comments`, `itineraries`, and
  `reviews`; adds a `public_profiles` view (name/avatar only) so posts,
  comments, conversations, and chat can show a name without exposing full
  profiles; adds a `payment_status` column to `bookings`; creates a public
  `uploads` Storage bucket (with RLS) for review/post photos; and seeds a
  handful of sample travel agents.
- `0004_fixes.sql` adds a unique index on `conversations` so two
  near-simultaneous "message this person for the first time" requests
  can't create duplicate conversation rows for the same pair of users.

In **Authentication → Providers**, email/password sign-up should already be
enabled by default. If **Confirm email** is also on (the default for new
projects), a signed-up user won't have a session until they confirm — the
app already handles this (shows a "check your email" screen instead of
bouncing them around), no action needed here.

### Password reset deep link

Forgot-password emails link back into the app via the custom URL scheme
`ona://reset-callback` (already registered natively for both Android and
iOS — see `android/app/src/main/AndroidManifest.xml` and
`ios/Runner/Info.plist`). For the link to actually work, add it to
**Authentication → URL Configuration → Redirect URLs** in the Supabase
dashboard:

```
ona://reset-callback
```

Without this, Supabase will reject the redirect and the reset email's link
won't return the user to the app.

### Google and Apple sign-in (optional)

The sign-in and sign-up screens show "Continue with Google" and "Continue
with Apple" buttons. Both use Supabase's native ID-token flow
(`signInWithIdToken` in `lib/features/auth/auth_controller.dart`), so no
extra dependency exists on Supabase's own OAuth redirect. Each provider
needs first-party credentials before it'll work:

**Google:**

1. In [Google Cloud Console](https://console.cloud.google.com/apis/credentials),
   create three OAuth 2.0 Client IDs (same project):
   - **Web application** — no redirect URIs needed for this flow. This is
     the "web client ID".
   - **iOS** — bundle ID `com.onathewayfinder.ona`.
   - **Android** — package name `com.digitalninjatechnologies.ona`, plus
     your debug/release keystore's SHA-1 fingerprint (`./gradlew
     signingReport` from `android/`).
2. In the Supabase dashboard, go to **Authentication → Providers → Google**,
   enable it, and paste the **web client ID** into "Authorized Client IDs".
3. In `ios/Runner/Info.plist`, replace
   `REPLACE_WITH_REVERSED_IOS_CLIENT_ID` in the `CFBundleURLTypes` entry
   with your iOS client ID reversed (an ID like
   `1234-abc.apps.googleusercontent.com` becomes
   `com.googleusercontent.apps.1234-abc`).
4. Run with both client IDs:

   ```bash
   flutter run \
     --dart-define=GOOGLE_WEB_CLIENT_ID=<web-client-id>.apps.googleusercontent.com \
     --dart-define=GOOGLE_IOS_CLIENT_ID=<ios-client-id>.apps.googleusercontent.com
   ```

   The Android client ID isn't passed at runtime — Google Sign-In on
   Android matches it automatically by package name + SHA-1.

**Apple:**

1. In your [Apple Developer account](https://developer.apple.com/account),
   make sure "Sign in with Apple" is enabled for the app ID
   `com.onathewayfinder.ona` (Xcode will offer to do this the
   first time you build, since the entitlement is already checked in at
   `ios/Runner/Runner.entitlements`).
2. In the Supabase dashboard, go to **Authentication → Providers → Apple**
   and enable it — the default settings work for native sign-in from the
   app (no Services ID/redirect setup needed for iOS).
3. No dart-defines needed. The button only appears where
   `SignInWithApple.isAvailable()` returns true (iOS/macOS), since the
   native flow isn't set up for other platforms here.

Until configured, tapping either button surfaces an error instead of
crashing.

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

## 3. Install Flutter dependencies

```bash
flutter pub get
```

Stage 3 adds `http` (live currency rates), `share_plus` (sharing
itineraries), `image_picker` (review/post photos), and `url_launcher`
(tap-to-call on the emergency contacts screen).

## 4. (Optional) AI features: assistant + itinerary generation

The AI assistant chat and "Generate with AI" itinerary flow call two
Supabase Edge Functions under `supabase/functions/`, which proxy to Gemini's
free tier (with a Groq fallback for when Gemini's rate limit is hit) using
server-side secrets — the app never holds an API key itself. To enable
them:

```bash
supabase functions deploy ai-assistant
supabase functions deploy generate-itinerary
supabase secrets set GEMINI_API_KEY=...
supabase secrets set GROQ_API_KEY=...
```

`GROQ_API_KEY` is optional but recommended — without it, a rate-limited
Gemini request just fails instead of falling back. The ai-assistant
function also optionally uses `BRAVE_API_KEY` for live web search grounding
(prices, hours, weather, news) — see the comment at the top of
`supabase/functions/ai-assistant/index.ts` for details. Override the models
with `supabase secrets set GEMINI_MODEL=...` / `GROQ_MODEL=...` if you want
different ones. Without a deployed function + secret, tapping the AI
assistant or "Generate with AI" shows an error message — every other screen
works regardless.

## Verifying it works

1. `flutter analyze` and `flutter test` should both pass.
2. `flutter run` (with the dart-defines above) → walk onboarding → sign up
   → land on the Home tab → confirm the seeded destinations/experiences
   render → use Search → confirm results → check all six bottom tabs are
   reachable.
3. Tap a destination → detail page renders with attractions; tap the heart
   to save it, then check Profile → Wishlist shows it and removing it there
   deletes it. Tap "Write a Review" to leave a rating/comment (with an
   optional photo).
4. From Home, tap an experience → Book Now → pick a date, adjust
   participants, fill in the (simulated) payment form, confirm → lands on a
   booking confirmation screen.
5. Agents tab → search/filter travel agents → open one → "Message Agent"
   starts a conversation, visible from the Messages tab.
6. Itineraries tab → create one manually (add days/activities) or with AI
   (needs the Edge Function from step 4) → saved itinerary appears in the
   list, can be shared or deleted.
7. Community tab → filter by post type, create a post (with an optional
   photo), like/comment on a post.
8. Tap the sparkle floating button (Home or Community) → chat with the AI
   assistant (needs the Edge Function from step 4).
9. Profile → Travel Essentials → currency converter (live rates), packing
   checklist, cultural etiquette, safety tips, emergency contacts (tap to
   call).
10. In the Supabase dashboard, confirm: the new auth user has a matching row
    in `profiles`; the booking created a row in `bookings` (with
    `payment_status = 'paid'`) and incremented the linked
    `experiences.total_bookings`; the saved destination has a row in
    `saved_destinations`.

## Project structure

```
lib/
  core/
    config/    Supabase credentials (via --dart-define)
    data/      Repositories/providers for Supabase-backed data
    models/    Plain Dart data classes
    router/    go_router configuration
    theme/     Colors, text styles
    widgets/   Shared widgets (destination card)
assets/
  brand/     Ọ̀nà logo/mark PNGs (light- and dark-background variants),
             declared as a Flutter asset directory in pubspec.yaml
  features/
    auth/           Sign in, sign up, forgot password
    onboarding/     Welcome, interests
    home/           Home tab
    search/         Search (reached from Home, not a bottom tab)
    destination/    Destination detail
    experience/     Experience detail
    booking/        Booking flow (incl. simulated payment) + confirmation
    wishlist/       Saved destinations
    agents/         Travel agents list + detail (Agents tab)
    itineraries/    Itineraries list, create (manual/AI), detail (tab)
    messages/       Conversations list + chat (Messages tab)
    community/      Post feed, create post, comments (Community tab)
    reviews/        Shared reviews screen (destinations/experiences/agents)
    ai_assistant/   AI travel assistant chat screen
    essentials/     Currency converter, packing checklist, etiquette,
                    safety tips, emergency contacts
    profile/        Profile tab (user info, wishlist/itineraries/essentials
                    links, sign out)
    shell/          Bottom-tab shell
supabase/
  migrations/    SQL schema + seed data (apply in numeric order)
  functions/     Edge Functions (ai-assistant, generate-itinerary) — proxy
                 to Anthropic using a server-side secret
```
