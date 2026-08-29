-- Quote-repost ("quote tweet"): a new community_posts row that carries its
-- own commentary plus a reference to the post it's quoting. Nullable +
-- on delete set null (not cascade) so deleting the original just orphans
-- the reference instead of deleting the quote post itself — the app shows
-- no embed when quoted_post_id no longer resolves.

alter table public.community_posts
  add column if not exists quoted_post_id uuid
    references public.community_posts (id) on delete set null;

create index if not exists community_posts_quoted_post_idx
  on public.community_posts (quoted_post_id);
