-- ---------------------------------------------------------------------------
-- Users can only start a conversation with each other once they mutually
-- follow each other. Messaging a travel agent is exempt — that's a business
-- flow (see agent_detail_screen's "Message Agent"), not the social-graph
-- messaging this restricts, and shouldn't require the agent to follow back.
-- ---------------------------------------------------------------------------

drop policy if exists "conversations are insertable by participants" on public.conversations;

create policy "conversations require mutual follow or an agent" on public.conversations
  for insert with check (
    (auth.uid() = user1_id or auth.uid() = user2_id)
    and (
      exists (
        select 1 from public.travel_agents ta
        where ta.user_id = user1_id or ta.user_id = user2_id
      )
      or (
        exists (
          select 1 from public.follows f
          where f.follower_id = user1_id and f.followed_id = user2_id
        )
        and exists (
          select 1 from public.follows f
          where f.follower_id = user2_id and f.followed_id = user1_id
        )
      )
    )
  );
