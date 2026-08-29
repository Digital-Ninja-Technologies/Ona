-- ---------------------------------------------------------------------------
-- Let a user delete their own notifications (swipe-to-delete on the
-- Notifications screen).
-- ---------------------------------------------------------------------------

create policy "notifications are deletable by recipient" on public.notifications
  for delete using (auth.uid() = user_id);
