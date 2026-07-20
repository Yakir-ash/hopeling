-- Missions: the observation archive. Insert-only, idempotent by the
-- client-generated observation UUID, owner-scoped, withdrawable.
-- No location column exists: precise location cannot leak because it
-- cannot be stored. Run once in the Supabase SQL Editor.

create table if not exists observations (
  obs_id uuid primary key,
  user_id uuid not null default auth.uid(),
  mission_id text not null,
  day text not null,
  payload jsonb not null,
  withdrawn boolean not null default false,
  created_at timestamptz not null default now()
);

alter table observations enable row level security;
create policy obs_own_insert on observations
  for insert to authenticated with check (auth.uid() = user_id);
create policy obs_own_select on observations
  for select to authenticated using (auth.uid() = user_id);
create policy obs_own_withdraw on observations
  for update to authenticated
  using (auth.uid() = user_id) with check (auth.uid() = user_id);

create or replace function submit_observation(
  oid uuid, mid text, d text, body jsonb)
returns boolean
language plpgsql security definer set search_path = public as $$
begin
  -- schema guards: bounded payload, sane day, known-shaped id
  if length(body::text) > 2000 or length(mid) > 64 then
    return false;
  end if;
  if abs(to_date(d, 'YYYY-MM-DD') - current_date) > 3 then
    return false;
  end if;
  insert into observations (obs_id, mission_id, day, payload)
  values (oid, mid, d, body)
  on conflict (obs_id) do nothing;
  return found; -- true accepted, false duplicate/invalid
end $$;

revoke execute on function submit_observation(uuid, text, text, jsonb)
  from public, anon;
grant execute on function submit_observation(uuid, text, text, jsonb)
  to authenticated;
