-- Slice 8: the truthful pulse. Events are canonical and idempotent:
-- the same event_id is accepted exactly once, duplicates return false,
-- and the counter only ever moves on a genuinely new event.
-- Run once in the Supabase SQL Editor.

create table if not exists pulse_events (
  event_id uuid primary key,
  user_id uuid not null default auth.uid(),
  day text not null,
  n int not null default 1 check (n between 1 and 50),
  created_at timestamptz not null default now()
);

alter table pulse_events enable row level security;
-- No public read: events are counting infrastructure, not a feed.
create policy pe_own_insert on pulse_events
  for insert to authenticated with check (auth.uid() = user_id);

create or replace function log_event(eid uuid, d text, cnt int)
returns boolean
language plpgsql security definer set search_path = public as $$
begin
  if cnt < 1 or cnt > 50 then
    return false;
  end if;
  -- Impossible-timestamp guard: the client's civil day may differ from the
  -- server's by at most one day in either direction (timezones), no more.
  if abs(to_date(d, 'YYYY-MM-DD') - current_date) > 1 then
    return false;
  end if;
  insert into pulse_events (event_id, day, n)
  values (eid, d, cnt)
  on conflict (event_id) do nothing;
  if found then
    update pulse set actions = actions + cnt where id = 1;
    return true;   -- accepted
  end if;
  return false;    -- duplicate: already counted, never counted twice
end $$;

revoke execute on function log_event(uuid, text, int) from public, anon;
grant execute on function log_event(uuid, text, int) to authenticated;
