-- Lets a comment be a reply to another comment on the same post — "reply to
-- a reply" is flattened to one level in the app (it attaches to the root
-- comment, prefixed with "@author"), so a single self-referencing column is
-- enough; no separate depth/thread table needed.

alter table public.post_comments
  add column if not exists parent_comment_id uuid
    references public.post_comments (id) on delete cascade;

create index if not exists post_comments_parent_idx
  on public.post_comments (parent_comment_id);
