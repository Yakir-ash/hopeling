-- Hopeling backend schema v2: circles. Run once in Supabase SQL Editor (after schema.sql).
-- Model: private circles joined by invite code. Membership rows carry each
-- member's public-to-the-circle stats. All writes flow through capped paths.

create table if not exists public.circles (
  id uuid primary key default gen_random_uuid(),
  name text not null check (char_length(name) between 1 and 30),
  code text unique not null check (code ~ '^[A-Z]{6}$'),
  created_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now()
);

create table if not exists public.members (
  circle_id uuid not null references public.circles(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  name text not null check (char_length(name) between 1 and 24),
  week text not null default '',
  week_actions int not null default 0 check (week_actions between 0 and 1000),
  streak int not null default 0 check (streak between 0 and 20000),
  total_actions int not null default 0 check (total_actions between 0 and 1000000),
  stage int not null default 0 check (stage between 0 and 10),
  joined_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  primary key (circle_id, user_id)
);

-- helper: is the caller a member of this circle? (security definer avoids RLS recursion)
create or replace function public.is_member(cid uuid)
returns boolean language sql security definer stable set search_path = public as $$
  select exists (select 1 from members where circle_id = cid and user_id = auth.uid());
$$;

alter table public.circles enable row level security;
alter table public.members enable row level security;

create policy "circles: member read" on public.circles
  for select using (public.is_member(id));

create policy "members: circle read" on public.members
  for select using (public.is_member(circle_id));
create policy "members: update self" on public.members
  for update using (user_id = auth.uid()) with check (user_id = auth.uid());
create policy "members: leave" on public.members
  for delete using (user_id = auth.uid());
-- no direct insert policy: joining happens only through the RPCs below

create or replace function public.create_circle(cname text, dname text)
returns json language plpgsql security definer set search_path = public as $$
declare uid uuid := auth.uid(); c record; newcode text; tries int := 0;
begin
  if uid is null then raise exception 'not signed in'; end if;
  if (select count(*) from members where user_id = uid) >= 5 then
    raise exception 'you are already in 5 circles';
  end if;
  if char_length(trim(cname)) not between 1 and 30 then raise exception 'circle name must be 1-30 characters'; end if;
  if char_length(trim(dname)) not between 1 and 24 then raise exception 'display name must be 1-24 characters'; end if;
  loop
    newcode := array_to_string(array(
      select substr('ABCDEFGHJKLMNPQRSTUVWXYZ', 1 + floor(random()*24)::int, 1)
      from generate_series(1, 6)), '');
    exit when not exists (select 1 from circles where code = newcode);
    tries := tries + 1;
    if tries > 20 then raise exception 'could not generate a code, try again'; end if;
  end loop;
  insert into circles (name, code, created_by) values (trim(cname), newcode, uid) returning * into c;
  insert into members (circle_id, user_id, name) values (c.id, uid, trim(dname));
  return json_build_object('id', c.id, 'code', c.code, 'name', c.name);
end $$;

create or replace function public.join_circle(ccode text, dname text)
returns json language plpgsql security definer set search_path = public as $$
declare uid uuid := auth.uid(); c record;
begin
  if uid is null then raise exception 'not signed in'; end if;
  if char_length(trim(dname)) not between 1 and 24 then raise exception 'display name must be 1-24 characters'; end if;
  select * into c from circles where code = upper(trim(ccode));
  if c.id is null then raise exception 'no circle with that code'; end if;
  if (select count(*) from members where circle_id = c.id) >= 12 then
    raise exception 'that circle is full (12 members)';
  end if;
  if (select count(*) from members where user_id = uid) >= 5
     and not exists (select 1 from members where circle_id = c.id and user_id = uid) then
    raise exception 'you are already in 5 circles';
  end if;
  insert into members (circle_id, user_id, name) values (c.id, uid, trim(dname))
    on conflict (circle_id, user_id) do update set name = trim(dname);
  return json_build_object('id', c.id, 'code', c.code, 'name', c.name);
end $$;

revoke all on function public.create_circle(text, text) from public;
revoke all on function public.create_circle(text, text) from anon;
grant execute on function public.create_circle(text, text) to authenticated;
revoke all on function public.join_circle(text, text) from public;
revoke all on function public.join_circle(text, text) from anon;
grant execute on function public.join_circle(text, text) to authenticated;

-- keep member stats honest on update
create or replace function public.members_guard()
returns trigger language plpgsql as $$
begin
  new.updated_at := now();
  return new;
end $$;
drop trigger if exists members_guard on public.members;
create trigger members_guard before update on public.members
  for each row execute function public.members_guard();
