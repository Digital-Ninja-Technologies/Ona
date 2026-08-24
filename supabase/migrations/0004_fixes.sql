-- QA-audit follow-up fixes.

-- ---------------------------------------------------------------------------
-- Prevent duplicate conversations between the same pair of users.
-- getOrCreateConversation() already checks-then-inserts, but two
-- near-simultaneous first-contact requests could both pass the check before
-- either insert lands. This unique index makes the pairing authoritative at
-- the DB level regardless of which user is user1 vs user2; the app catches
-- the resulting unique-violation and falls back to re-selecting the
-- existing row instead of erroring.
-- ---------------------------------------------------------------------------
create unique index if not exists conversations_unique_pair
  on public.conversations (least(user1_id, user2_id), greatest(user1_id, user2_id));
