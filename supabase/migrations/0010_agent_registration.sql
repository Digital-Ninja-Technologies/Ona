-- ---------------------------------------------------------------------------
-- Let a signed-in user register (and later update) their own travel_agents
-- row, so "Register as an agent" on Profile can write directly to the table
-- that already backs the public agents list and agent detail page.
-- ---------------------------------------------------------------------------

-- One agent profile per user account.
alter table public.travel_agents
  add constraint travel_agents_user_id_unique unique (user_id);

create policy "travel_agents are insertable by owner" on public.travel_agents
  for insert with check (auth.uid() = user_id);

create policy "travel_agents are updatable by owner" on public.travel_agents
  for update using (auth.uid() = user_id) with check (auth.uid() = user_id);
