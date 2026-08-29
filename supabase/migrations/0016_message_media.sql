-- ---------------------------------------------------------------------------
-- Media sharing in chats: a message can now carry an image instead of (or
-- alongside) text. Content becomes optional, guarded by a check that at
-- least one of content/image_url is present.
-- ---------------------------------------------------------------------------

alter table public.messages alter column content drop not null;
alter table public.messages add column if not exists image_url text;
alter table public.messages
  add constraint messages_content_or_image check (content is not null or image_url is not null);
