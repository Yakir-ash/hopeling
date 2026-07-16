-- Hopeling feedback inbox. Run once in Supabase SQL Editor.
create table if not exists public.feedback (
  id uuid primary key default gen_random_uuid(),
  created_at timestamptz not null default now(),
  user_id uuid references auth.users(id) on delete set null,
  email text check (email is null or char_length(email) <= 120),
  message text not null check (char_length(message) between 3 and 2000),
  meta text check (meta is null or char_length(meta) <= 300)
);
alter table public.feedback enable row level security;
create policy "feedback: anyone may write" on public.feedback
  for insert to anon, authenticated with check (true);
-- no select policy: only you, via the dashboard, can read
grant insert on public.feedback to anon, authenticated;
