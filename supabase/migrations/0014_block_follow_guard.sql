-- ---------------------------------------------------------------------------
-- A blocked user shouldn't be able to re-follow you (or you them) while the
-- block stands — the block-confirmation dialog already claims this.
-- ---------------------------------------------------------------------------

drop policy if exists "follows are insertable by follower" on public.follows;

create policy "follows are insertable unless blocked" on public.follows
  for insert with check (
    auth.uid() = follower_id
    and not exists (
      select 1 from public.blocks b
      where (b.blocker_id = follower_id and b.blocked_id = followed_id)
         or (b.blocker_id = followed_id and b.blocked_id = follower_id)
    )
  );
