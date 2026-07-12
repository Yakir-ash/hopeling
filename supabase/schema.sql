-- Hopeling backend schema v1: saves + pulse. Run once in Supabase SQL Editor.
-- Security model: Row Level Security everywhere; users touch only their own rows;
-- the global counter moves only through a rate-capped function.

-- per-user cloud backup
create table if not exists public.saves (
  user_id uuid primary key references auth.users(id) on delete cascade,
  data jsonb not null,
  updated_at timestamptz not null default now()
);
alter table public.saves enable row level security;

create policy "saves: own read"   on public.saves for select using (auth.uid() = user_id);
create policy "saves: own insert" on public.saves for insert with check (auth.uid() = user_id);
create policy "saves: own update" on public.saves for update using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy "saves: own delete" on public.saves for delete using (auth.uid() = user_id);

-- guard: a backup can't be absurdly large (200 KB is ~20x a real save)
create or replace function public.saves_size_guard()
returns trigger language plpgsql as $$
begin
  if pg_column_size(new.data) > 200000 then
    raise exception 'backup too large';
  end if;
  new.updated_at := now();
  return new;
end $$;
drop trigger if exists saves_size_guard on public.saves;
create trigger saves_size_guard before insert or update on public.saves
  for each row execute function public.saves_size_guard();

-- the pulse: one global row, everyone can read, nobody can write directly
create table if not exists public.pulse (
  id int primary key check (id = 1),
  actions bigint not null default 0
);
insert into public.pulse (id, actions) values (1, 0) on conflict (id) do nothing;
alter table public.pulse enable row level security;
create policy "pulse: public read" on public.pulse for select using (true);

-- signed-in users report action counts through this capped function only
create or replace function public.log_actions(n int)
returns void
language sql
security definer
set search_path = public
as $$
  update public.pulse
     set actions = actions + greatest(0, least(n, 50))
   where id = 1;
$$;
revoke all on function public.log_actions(int) from public;
revoke all on function public.log_actions(int) from anon;
grant execute on function public.log_actions(int) to authenticated;
