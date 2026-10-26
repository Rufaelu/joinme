-- JoinMe database schema for Supabase.
-- Paste this whole file into the Supabase SQL Editor and run it.
-- Safe to re-run: tables are created only if missing, functions/policies are replaced.

-- ---------------------------------------------------------------------------
-- Tables
-- ---------------------------------------------------------------------------

create table if not exists public.profiles (
  id uuid primary key references auth.users (id) on delete cascade,
  name text not null check (char_length(trim(name)) > 0),
  bio text,
  created_at timestamptz not null default now()
);

create table if not exists public.events (
  id uuid primary key default gen_random_uuid(),
  host_id uuid not null default auth.uid() references public.profiles (id) on delete cascade,
  title text not null check (char_length(trim(title)) > 0),
  category text not null,
  description text,
  location_name text not null,
  lat double precision not null,
  lng double precision not null,
  starts_at timestamptz not null,
  ends_at timestamptz not null,
  group_size int not null check (group_size between 2 and 50),
  created_at timestamptz not null default now(),
  check (ends_at > starts_at)
);

create table if not exists public.event_groups (
  id uuid primary key default gen_random_uuid(),
  event_id uuid not null references public.events (id) on delete cascade,
  number int not null,
  created_at timestamptz not null default now(),
  unique (event_id, number)
);

create table if not exists public.group_members (
  group_id uuid not null references public.event_groups (id) on delete cascade,
  user_id uuid not null references public.profiles (id) on delete cascade,
  joined_at timestamptz not null default now(),
  primary key (group_id, user_id)
);

create table if not exists public.messages (
  id bigint generated always as identity primary key,
  group_id uuid not null references public.event_groups (id) on delete cascade,
  sender_id uuid not null default auth.uid() references public.profiles (id) on delete cascade,
  body text not null check (char_length(trim(body)) between 1 and 2000),
  created_at timestamptz not null default now()
);

create table if not exists public.event_ratings (
  event_id uuid not null references public.events (id) on delete cascade,
  rater_id uuid not null default auth.uid() references public.profiles (id) on delete cascade,
  event_score smallint not null check (event_score between 1 and 5),
  -- null when the rater is the host
  host_score smallint check (host_score between 1 and 5),
  created_at timestamptz not null default now(),
  primary key (event_id, rater_id)
);

create table if not exists public.user_ratings (
  event_id uuid not null references public.events (id) on delete cascade,
  rater_id uuid not null default auth.uid() references public.profiles (id) on delete cascade,
  ratee_id uuid not null references public.profiles (id) on delete cascade,
  score smallint not null check (score between 1 and 5),
  created_at timestamptz not null default now(),
  primary key (event_id, rater_id, ratee_id),
  check (rater_id <> ratee_id)
);

create index if not exists events_ends_at_idx on public.events (ends_at);
create index if not exists event_groups_event_idx on public.event_groups (event_id);
create index if not exists group_members_user_idx on public.group_members (user_id);
create index if not exists messages_group_idx on public.messages (group_id, created_at);
create index if not exists user_ratings_ratee_idx on public.user_ratings (ratee_id);

-- ---------------------------------------------------------------------------
-- Helper functions (security definer so policies can call them without recursion)
-- ---------------------------------------------------------------------------

create or replace function public.is_group_member(g uuid)
returns boolean
language sql stable security definer set search_path = ''
as $$
  select exists (
    select 1 from public.group_members
    where group_id = g and user_id = auth.uid()
  );
$$;

create or replace function public.is_event_member(e uuid, u uuid)
returns boolean
language sql stable security definer set search_path = ''
as $$
  select exists (
    select 1 from public.group_members gm
    join public.event_groups g on g.id = gm.group_id
    where g.event_id = e and gm.user_id = u
  );
$$;

create or replace function public.shares_group(e uuid, a uuid, b uuid)
returns boolean
language sql stable security definer set search_path = ''
as $$
  select exists (
    select 1 from public.group_members ga
    join public.group_members gb on gb.group_id = ga.group_id
    join public.event_groups g on g.id = ga.group_id
    where g.event_id = e and ga.user_id = a and gb.user_id = b
  );
$$;

-- ---------------------------------------------------------------------------
-- Triggers
-- ---------------------------------------------------------------------------

-- Create a profile row for every new auth user.
create or replace function public.handle_new_user()
returns trigger
language plpgsql security definer set search_path = ''
as $$
begin
  insert into public.profiles (id, name)
  values (
    new.id,
    coalesce(nullif(trim(new.raw_user_meta_data ->> 'name'), ''), split_part(new.email, '@', 1))
  )
  on conflict (id) do nothing;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- Every new event gets group 1 with the host in it.
create or replace function public.handle_new_event()
returns trigger
language plpgsql security definer set search_path = ''
as $$
declare
  gid uuid;
begin
  insert into public.event_groups (event_id, number) values (new.id, 1) returning id into gid;
  insert into public.group_members (group_id, user_id) values (gid, new.host_id);
  return new;
end;
$$;

drop trigger if exists on_event_created on public.events;
create trigger on_event_created
  after insert on public.events
  for each row execute function public.handle_new_event();

-- ---------------------------------------------------------------------------
-- join_event: put the caller in the first group with room, or open a new one.
-- Returns the group id. Calling it again returns the group you are already in.
-- ---------------------------------------------------------------------------

create or replace function public.join_event(p_event_id uuid)
returns uuid
language plpgsql security definer set search_path = ''
as $$
declare
  ev public.events;
  gid uuid;
begin
  if auth.uid() is null then
    raise exception 'You must be signed in';
  end if;

  -- lock the event row so concurrent joins serialize
  select * into ev from public.events where id = p_event_id for update;
  if not found then
    raise exception 'Event not found';
  end if;
  if ev.ends_at <= now() then
    raise exception 'This event has ended';
  end if;

  select gm.group_id into gid
  from public.group_members gm
  join public.event_groups g on g.id = gm.group_id
  where g.event_id = p_event_id and gm.user_id = auth.uid();
  if gid is not null then
    return gid;
  end if;

  select g.id into gid
  from public.event_groups g
  where g.event_id = p_event_id
    and (select count(*) from public.group_members m where m.group_id = g.id) < ev.group_size
  order by g.number
  limit 1;

  if gid is null then
    insert into public.event_groups (event_id, number)
    values (
      p_event_id,
      coalesce((select max(number) from public.event_groups where event_id = p_event_id), 0) + 1
    )
    returning id into gid;
  end if;

  insert into public.group_members (group_id, user_id) values (gid, auth.uid());
  return gid;
end;
$$;

revoke execute on function public.join_event(uuid) from public, anon;
grant execute on function public.join_event(uuid) to authenticated;

-- ---------------------------------------------------------------------------
-- Views
-- ---------------------------------------------------------------------------

create or replace view public.profile_stats
with (security_invoker = on) as
with received as (
  select ur.ratee_id as uid, ur.score::numeric as s
  from public.user_ratings ur
  union all
  select e.host_id, er.host_score::numeric
  from public.event_ratings er
  join public.events e on e.id = er.event_id
  where er.host_score is not null
)
select
  p.id,
  p.name,
  p.bio,
  (select round(avg(r.s), 1) from received r where r.uid = p.id) as reputation,
  (select count(*) from received r where r.uid = p.id)::int as rating_count,
  (select count(*) from public.events e where e.host_id = p.id)::int as events_hosted,
  (
    select count(distinct g.event_id)
    from public.group_members gm
    join public.event_groups g on g.id = gm.group_id
    join public.events e on e.id = g.event_id
    where gm.user_id = p.id and e.host_id <> p.id and e.ends_at < now()
  )::int as events_attended
from public.profiles p;

create or replace view public.event_feed
with (security_invoker = on) as
select
  e.*,
  ps.name as host_name,
  ps.reputation as host_reputation,
  ps.rating_count as host_rating_count,
  (
    select count(*) from public.group_members gm
    join public.event_groups g on g.id = gm.group_id
    where g.event_id = e.id
  )::int as member_count,
  (select count(*) from public.event_groups g where g.event_id = e.id)::int as group_count
from public.events e
join public.profile_stats ps on ps.id = e.host_id;

grant select on public.profile_stats, public.event_feed to authenticated;

-- ---------------------------------------------------------------------------
-- Row level security
-- ---------------------------------------------------------------------------

alter table public.profiles enable row level security;
alter table public.events enable row level security;
alter table public.event_groups enable row level security;
alter table public.group_members enable row level security;
alter table public.messages enable row level security;
alter table public.event_ratings enable row level security;
alter table public.user_ratings enable row level security;

-- profiles
drop policy if exists "profiles readable" on public.profiles;
create policy "profiles readable" on public.profiles
  for select to authenticated using (true);
drop policy if exists "profiles update own" on public.profiles;
create policy "profiles update own" on public.profiles
  for update to authenticated using (id = auth.uid()) with check (id = auth.uid());

-- events
drop policy if exists "events readable" on public.events;
create policy "events readable" on public.events
  for select to authenticated using (true);
drop policy if exists "events insert own" on public.events;
create policy "events insert own" on public.events
  for insert to authenticated with check (host_id = auth.uid());
drop policy if exists "events update own" on public.events;
create policy "events update own" on public.events
  for update to authenticated using (host_id = auth.uid()) with check (host_id = auth.uid());
drop policy if exists "events delete own" on public.events;
create policy "events delete own" on public.events
  for delete to authenticated using (host_id = auth.uid());

-- groups and members: readable by everyone signed in (for counts); written only
-- by join_event / the event trigger. Members may leave.
drop policy if exists "groups readable" on public.event_groups;
create policy "groups readable" on public.event_groups
  for select to authenticated using (true);
drop policy if exists "members readable" on public.group_members;
create policy "members readable" on public.group_members
  for select to authenticated using (true);
drop policy if exists "members leave" on public.group_members;
create policy "members leave" on public.group_members
  for delete to authenticated using (user_id = auth.uid());

-- messages: group members only
drop policy if exists "messages read by members" on public.messages;
create policy "messages read by members" on public.messages
  for select to authenticated using (public.is_group_member(group_id));
drop policy if exists "messages send by members" on public.messages;
create policy "messages send by members" on public.messages
  for insert to authenticated
  with check (sender_id = auth.uid() and public.is_group_member(group_id));

-- event ratings: once, by a member, after the event ended. The host leaves host_score empty.
drop policy if exists "event ratings readable" on public.event_ratings;
create policy "event ratings readable" on public.event_ratings
  for select to authenticated using (true);
drop policy if exists "event ratings insert" on public.event_ratings;
create policy "event ratings insert" on public.event_ratings
  for insert to authenticated
  with check (
    rater_id = auth.uid()
    and public.is_event_member(event_id, auth.uid())
    and exists (
      select 1 from public.events e
      where e.id = event_id
        and e.ends_at < now()
        and ((e.host_id = auth.uid()) = (host_score is null))
    )
  );

-- user ratings: people you shared a group with, after the event ended.
-- The host is rated through event_ratings.host_score, not here.
drop policy if exists "user ratings readable" on public.user_ratings;
create policy "user ratings readable" on public.user_ratings
  for select to authenticated using (true);
drop policy if exists "user ratings insert" on public.user_ratings;
create policy "user ratings insert" on public.user_ratings
  for insert to authenticated
  with check (
    rater_id = auth.uid()
    and ratee_id <> auth.uid()
    and public.shares_group(event_id, auth.uid(), ratee_id)
    and exists (
      select 1 from public.events e
      where e.id = event_id and e.ends_at < now() and e.host_id <> ratee_id
    )
  );

-- ---------------------------------------------------------------------------
-- Realtime
-- ---------------------------------------------------------------------------

do $$
declare
  t text;
begin
  foreach t in array array['messages', 'events', 'group_members'] loop
    if not exists (
      select 1 from pg_publication_tables
      where pubname = 'supabase_realtime' and schemaname = 'public' and tablename = t
    ) then
      execute format('alter publication supabase_realtime add table public.%I', t);
    end if;
  end loop;
end;
$$;
