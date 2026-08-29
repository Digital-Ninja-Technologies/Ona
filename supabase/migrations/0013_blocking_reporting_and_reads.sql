-- ---------------------------------------------------------------------------
-- Twitter-style DM moderation: block, report, one-sided conversation delete,
-- and per-user read tracking (for the Messages screen's All/Read/Unread
-- filter — "Requests" is derived from the follows table at query time, no
-- schema needed for that bucket).
--
-- Also relaxes conversation creation: the mutual-follow requirement added in
-- 0012 is replaced here — anyone can message anyone (a message from someone
-- you don't follow back is simply a "request"), except across a block.
-- ---------------------------------------------------------------------------

-- blocks
-- ---------------------------------------------------------------------------
create table if not exists public.blocks (
  blocker_id uuid not null references auth.users (id) on delete cascade,
  blocked_id uuid not null references auth.users (id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (blocker_id, blocked_id),
  constraint blocks_no_self_block check (blocker_id <> blocked_id)
);

create index if not exists blocks_blocked_idx on public.blocks (blocked_id);

alter table public.blocks enable row level security;

create policy "blocks are readable by either party" on public.blocks
  for select using (auth.uid() = blocker_id or auth.uid() = blocked_id);

create policy "blocks are insertable by blocker" on public.blocks
  for insert with check (auth.uid() = blocker_id);

create policy "blocks are deletable by blocker" on public.blocks
  for delete using (auth.uid() = blocker_id);

-- Blocking someone drops any follow relationship between the two, both
-- ways — matches Twitter (blocking implies unfollowing each other).
create or replace function public.handle_block_insert()
returns trigger
language plpgsql
security definer set search_path = public
as $$
begin
  delete from public.follows
    where (follower_id = new.blocker_id and followed_id = new.blocked_id)
       or (follower_id = new.blocked_id and followed_id = new.blocker_id);
  return new;
end;
$$;

create trigger on_block_insert
  after insert on public.blocks
  for each row execute function public.handle_block_insert();

-- user_reports
-- ---------------------------------------------------------------------------
create table if not exists public.user_reports (
  id uuid primary key default gen_random_uuid(),
  reporter_id uuid not null references auth.users (id) on delete cascade,
  reported_id uuid not null references auth.users (id) on delete cascade,
  reason text,
  created_at timestamptz not null default now()
);

alter table public.user_reports enable row level security;

create policy "user_reports are insertable by reporter" on public.user_reports
  for insert with check (auth.uid() = reporter_id);

create policy "user_reports are readable by reporter" on public.user_reports
  for select using (auth.uid() = reporter_id);

-- conversation_hidden — one-sided "delete conversation". Hiding only
-- affects the hider's own inbox, and only until a newer message arrives
-- (checked client-side: hidden_at compared against the conversation's
-- latest message time), matching Twitter's delete-conversation behavior.
-- ---------------------------------------------------------------------------
create table if not exists public.conversation_hidden (
  conversation_id uuid not null references public.conversations (id) on delete cascade,
  user_id uuid not null references auth.users (id) on delete cascade,
  hidden_at timestamptz not null default now(),
  primary key (conversation_id, user_id)
);

alter table public.conversation_hidden enable row level security;

create policy "conversation_hidden manageable by owner" on public.conversation_hidden
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

-- Per-user read tracking on conversations
-- ---------------------------------------------------------------------------
alter table public.conversations add column if not exists user1_last_read_at timestamptz;
alter table public.conversations add column if not exists user2_last_read_at timestamptz;

-- Security-definer RPC instead of a generic UPDATE policy, so a client can
-- only ever touch their own read-marker column, never the other columns.
create or replace function public.mark_conversation_read(p_conversation_id uuid)
returns void
language plpgsql
security definer set search_path = public
as $$
declare
  v_user1 uuid;
  v_user2 uuid;
begin
  select user1_id, user2_id into v_user1, v_user2
  from public.conversations
  where id = p_conversation_id;

  if v_user1 is null then
    return;
  end if;

  if auth.uid() = v_user1 then
    update public.conversations set user1_last_read_at = now() where id = p_conversation_id;
  elsif auth.uid() = v_user2 then
    update public.conversations set user2_last_read_at = now() where id = p_conversation_id;
  end if;
end;
$$;

grant execute on function public.mark_conversation_read(uuid) to authenticated;

-- Relax conversation creation: block-based only, not mutual-follow
-- ---------------------------------------------------------------------------
drop policy if exists "conversations require mutual follow or an agent" on public.conversations;

create policy "conversations are insertable unless blocked" on public.conversations
  for insert with check (
    (auth.uid() = user1_id or auth.uid() = user2_id)
    and not exists (
      select 1 from public.blocks b
      where (b.blocker_id = user1_id and b.blocked_id = user2_id)
         or (b.blocker_id = user2_id and b.blocked_id = user1_id)
    )
  );

-- Messages: same block check, as a safety net for a block made after a
-- conversation already exists.
drop policy if exists "messages are insertable by conversation participants" on public.messages;

create policy "messages are insertable unless blocked" on public.messages
  for insert with check (
    sender_id = auth.uid()
    and exists (
      select 1 from public.conversations c
      where c.id = conversation_id
        and (c.user1_id = auth.uid() or c.user2_id = auth.uid())
    )
    and not exists (
      select 1 from public.conversations c
      join public.blocks b
        on (b.blocker_id = c.user1_id and b.blocked_id = c.user2_id)
        or (b.blocker_id = c.user2_id and b.blocked_id = c.user1_id)
      where c.id = conversation_id
    )
  );
