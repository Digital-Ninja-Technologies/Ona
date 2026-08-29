-- ---------------------------------------------------------------------------
-- Long-press a message in a chat: reply, edit, or delete (copy is
-- client-side only, no schema needed). Reply quotes another message in the
-- same conversation; edit/delete are sender-only.
-- ---------------------------------------------------------------------------

alter table public.messages
  add column if not exists reply_to_id uuid references public.messages (id) on delete set null;
alter table public.messages add column if not exists edited_at timestamptz;

create policy "messages are updatable by sender" on public.messages
  for update using (auth.uid() = sender_id) with check (auth.uid() = sender_id);

create policy "messages are deletable by sender" on public.messages
  for delete using (auth.uid() = sender_id);
