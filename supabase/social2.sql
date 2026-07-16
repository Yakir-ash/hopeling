-- Hopeling presence trio: relay flame, cheers, named rain support. Run once in SQL Editor.
alter table public.members add column if not exists last_action date;
alter table public.circles add column if not exists flame_start date;
alter table public.circles add column if not exists flame_last date;

create or replace function public.feed_flame(cid uuid)
returns void language plpgsql security definer set search_path = public as $$
declare c record;
begin
  if auth.uid() is null or not public.is_member(cid) then raise exception 'not a member'; end if;
  select * into c from circles where id = cid;
  if c.flame_last = current_date then return; end if;
  if c.flame_last = current_date - 1 and c.flame_start is not null then
    update circles set flame_last = current_date where id = cid;
  else
    update circles set flame_start = current_date, flame_last = current_date where id = cid;
  end if;
end $$;
revoke all on function public.feed_flame(uuid) from public, anon;
grant execute on function public.feed_flame(uuid) to authenticated;

create table if not exists public.cheers (
  circle_id uuid not null references public.circles(id) on delete cascade,
  from_user uuid not null references auth.users(id) on delete cascade,
  to_user uuid not null,
  week text not null,
  emoji text not null default '💚' check (emoji in ('💚','👏','🔥')),
  primary key (circle_id, from_user, to_user, week)
);
alter table public.cheers enable row level security;
create policy "cheers: circle read" on public.cheers for select using (public.is_member(circle_id));
create policy "cheers: give" on public.cheers for insert to authenticated
  with check (from_user = auth.uid() and public.is_member(circle_id));
create policy "cheers: regive" on public.cheers for update to authenticated
  using (from_user = auth.uid()) with check (from_user = auth.uid());
grant select, insert, update on public.cheers to authenticated;
