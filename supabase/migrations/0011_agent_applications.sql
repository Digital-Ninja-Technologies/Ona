-- ---------------------------------------------------------------------------
-- "Register as an Agent" no longer writes straight to travel_agents — it
-- emails an application (see the submit-agent-application Edge Function) for
-- review instead. Drop the self-insert policy from 0010 so a listing can
-- only be created by an admin (service role), not by the applicant
-- themselves; keep the owner-update policy so an approved agent can still
-- edit their own listing afterwards.
-- ---------------------------------------------------------------------------

drop policy if exists "travel_agents are insertable by owner" on public.travel_agents;
