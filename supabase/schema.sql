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

-- Photos (added later; "if not exists" keeps re-runs safe on existing tables)
alter table public.profiles add column if not exists avatar_url text;
alter table public.events add column if not exists image_url text;

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
  -- Email sign-ups send "name"; Google sends "full_name"/"name" and "avatar_url"/"picture".
  insert into public.profiles (id, name, avatar_url)
  values (
    new.id,
    coalesce(
      nullif(trim(new.raw_user_meta_data ->> 'name'), ''),
      nullif(trim(new.raw_user_meta_data ->> 'full_name'), ''),
      split_part(new.email, '@', 1)
    ),
    coalesce(new.raw_user_meta_data ->> 'avatar_url', new.raw_user_meta_data ->> 'picture')
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
-- submit_ratings: the event/host rating and peer ratings in one transaction, so a
-- failure saves nothing and the user can retry. Runs as the caller, so the
-- insert policies below still apply. Peers who are no longer group mates are skipped.
-- p_peers: [{"ratee_id": "<uuid>", "score": 1-5}, ...]
-- ---------------------------------------------------------------------------

create or replace function public.submit_ratings(
  p_event_id uuid,
  p_event_score int,
  p_host_score int,
  p_peers jsonb default '[]'::jsonb
)
returns void
language plpgsql security invoker set search_path = ''
as $$
begin
  insert into public.event_ratings (event_id, rater_id, event_score, host_score)
  values (p_event_id, auth.uid(), p_event_score, p_host_score);

  insert into public.user_ratings (event_id, rater_id, ratee_id, score)
  select p_event_id, auth.uid(), (p ->> 'ratee_id')::uuid, (p ->> 'score')::int
  from jsonb_array_elements(coalesce(p_peers, '[]'::jsonb)) as p
  where public.shares_group(p_event_id, auth.uid(), (p ->> 'ratee_id')::uuid);
end;
$$;

revoke execute on function public.submit_ratings(uuid, int, int, jsonb) from public, anon;
grant execute on function public.submit_ratings(uuid, int, int, jsonb) to authenticated;

-- ---------------------------------------------------------------------------
-- Views
-- ---------------------------------------------------------------------------

-- Views are dropped and recreated so re-running this file picks up changes.
drop view if exists public.event_feed;
drop view if exists public.profile_stats;

-- Runs with the owner's rights (security_invoker off) so it can average ratings
-- that individual users are not allowed to read row by row.
create view public.profile_stats
with (security_invoker = off) as
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
  p.avatar_url,
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

create view public.event_feed
with (security_invoker = on) as
select
  e.*,
  ps.name as host_name,
  ps.avatar_url as host_avatar_url,
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

revoke all on public.profile_stats, public.event_feed from public, anon;
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
-- No update policy: events can't be edited, so a host can't move the end time
-- to open rating early or reopen a finished event.
drop policy if exists "events update own" on public.events;
-- Hosts may cancel (delete) only before the event starts, so ratings can't be wiped.
drop policy if exists "events delete own" on public.events;
create policy "events delete own" on public.events
  for delete to authenticated using (host_id = auth.uid() and starts_at > now());

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
-- Only your own ratings are readable; everyone else sees averages via profile_stats.
drop policy if exists "event ratings readable" on public.event_ratings;
create policy "event ratings readable" on public.event_ratings
  for select to authenticated using (rater_id = auth.uid());
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
  for select to authenticated using (rater_id = auth.uid());
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
-- Photo storage: public buckets (anyone with the link can view), and each user
-- may only upload/replace/delete files inside a folder named after their user id.
-- ---------------------------------------------------------------------------

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values
  ('avatars', 'avatars', true, 5242880, array['image/jpeg', 'image/png', 'image/webp']),
  ('event-images', 'event-images', true, 5242880, array['image/jpeg', 'image/png', 'image/webp'])
on conflict (id) do update
  set public = excluded.public,
      file_size_limit = excluded.file_size_limit,
      allowed_mime_types = excluded.allowed_mime_types;

drop policy if exists "photos upload own folder" on storage.objects;
create policy "photos upload own folder" on storage.objects
  for insert to authenticated
  with check (
    bucket_id in ('avatars', 'event-images')
    and (storage.foldername(name))[1] = auth.uid()::text
  );
drop policy if exists "photos update own folder" on storage.objects;
create policy "photos update own folder" on storage.objects
  for update to authenticated
  using (bucket_id in ('avatars', 'event-images') and (storage.foldername(name))[1] = auth.uid()::text);
drop policy if exists "photos delete own folder" on storage.objects;
create policy "photos delete own folder" on storage.objects
  for delete to authenticated
  using (bucket_id in ('avatars', 'event-images') and (storage.foldername(name))[1] = auth.uid()::text);

-- ---------------------------------------------------------------------------
-- Friends: one row per pair. Written only through the functions below.
-- ---------------------------------------------------------------------------

create table if not exists public.friendships (
  requester_id uuid not null references public.profiles (id) on delete cascade,
  addressee_id uuid not null references public.profiles (id) on delete cascade,
  status text not null default 'pending' check (status in ('pending', 'accepted')),
  created_at timestamptz not null default now(),
  responded_at timestamptz,
  primary key (requester_id, addressee_id),
  check (requester_id <> addressee_id)
);
create unique index if not exists friendships_pair_idx
  on public.friendships (least(requester_id, addressee_id), greatest(requester_id, addressee_id));
create index if not exists friendships_addressee_idx on public.friendships (addressee_id);

alter table public.friendships enable row level security;
drop policy if exists "friendships readable by both" on public.friendships;
create policy "friendships readable by both" on public.friendships
  for select to authenticated using (auth.uid() in (requester_id, addressee_id));

create or replace function public.are_friends(a uuid, b uuid)
returns boolean
language sql stable security definer set search_path = ''
as $$
  select exists (
    select 1 from public.friendships f
    where f.status = 'accepted'
      and least(f.requester_id, f.addressee_id) = least(a, b)
      and greatest(f.requester_id, f.addressee_id) = greatest(a, b)
  );
$$;

-- Sends a request, or accepts theirs if they already asked you. Returns 'pending' or 'accepted'.
create or replace function public.send_friend_request(p_user uuid)
returns text
language plpgsql security definer set search_path = ''
as $$
declare
  existing public.friendships;
begin
  if auth.uid() is null then raise exception 'You must be signed in'; end if;
  if p_user = auth.uid() then raise exception 'You cannot add yourself'; end if;

  select * into existing from public.friendships f
  where least(f.requester_id, f.addressee_id) = least(auth.uid(), p_user)
    and greatest(f.requester_id, f.addressee_id) = greatest(auth.uid(), p_user)
  for update;

  if not found then
    insert into public.friendships (requester_id, addressee_id) values (auth.uid(), p_user);
    return 'pending';
  end if;
  if existing.status = 'pending' and existing.addressee_id = auth.uid() then
    update public.friendships set status = 'accepted', responded_at = now()
    where requester_id = existing.requester_id and addressee_id = existing.addressee_id;
    return 'accepted';
  end if;
  return existing.status;
end;
$$;

-- Accept or decline a request someone sent you.
create or replace function public.respond_friend_request(p_requester uuid, p_accept boolean)
returns void
language plpgsql security definer set search_path = ''
as $$
begin
  if p_accept then
    update public.friendships set status = 'accepted', responded_at = now()
    where requester_id = p_requester and addressee_id = auth.uid() and status = 'pending';
  else
    delete from public.friendships
    where requester_id = p_requester and addressee_id = auth.uid() and status = 'pending';
  end if;
  if not found then raise exception 'Friend request not found'; end if;
end;
$$;

-- Unfriend, or cancel a request you sent.
create or replace function public.remove_friend(p_user uuid)
returns void
language sql security definer set search_path = ''
as $$
  delete from public.friendships f
  where least(f.requester_id, f.addressee_id) = least(auth.uid(), p_user)
    and greatest(f.requester_id, f.addressee_id) = greatest(auth.uid(), p_user);
$$;

revoke execute on function public.are_friends(uuid, uuid) from public, anon;
revoke execute on function public.send_friend_request(uuid) from public, anon;
revoke execute on function public.respond_friend_request(uuid, boolean) from public, anon;
revoke execute on function public.remove_friend(uuid) from public, anon;
grant execute on function public.are_friends(uuid, uuid) to authenticated;
grant execute on function public.send_friend_request(uuid) to authenticated;
grant execute on function public.respond_friend_request(uuid, boolean) to authenticated;
grant execute on function public.remove_friend(uuid) to authenticated;

-- ---------------------------------------------------------------------------
-- Direct messages between friends. pair_key groups both directions of a chat.
-- ---------------------------------------------------------------------------

create table if not exists public.direct_messages (
  id bigint generated always as identity primary key,
  sender_id uuid not null default auth.uid() references public.profiles (id) on delete cascade,
  recipient_id uuid not null references public.profiles (id) on delete cascade,
  pair_key text generated always as (
    least(sender_id, recipient_id)::text || ':' || greatest(sender_id, recipient_id)::text
  ) stored,
  body text not null check (char_length(trim(body)) between 1 and 2000),
  created_at timestamptz not null default now(),
  check (sender_id <> recipient_id)
);
create index if not exists direct_messages_pair_idx on public.direct_messages (pair_key, created_at);

alter table public.direct_messages enable row level security;
drop policy if exists "dms readable by both" on public.direct_messages;
create policy "dms readable by both" on public.direct_messages
  for select to authenticated using (auth.uid() in (sender_id, recipient_id));
drop policy if exists "dms sent to friends" on public.direct_messages;
create policy "dms sent to friends" on public.direct_messages
  for insert to authenticated
  with check (sender_id = auth.uid() and public.are_friends(sender_id, recipient_id));

-- ---------------------------------------------------------------------------
-- Notifications: written by triggers, read (and marked read) by their owner.
-- ---------------------------------------------------------------------------

create table if not exists public.notifications (
  id bigint generated always as identity primary key,
  user_id uuid not null references public.profiles (id) on delete cascade,
  type text not null check (type in ('friend_request', 'friend_accepted', 'event_joined', 'direct_message')),
  actor_id uuid references public.profiles (id) on delete cascade,
  event_id uuid references public.events (id) on delete cascade,
  body text not null,
  read boolean not null default false,
  created_at timestamptz not null default now()
);
create index if not exists notifications_user_idx on public.notifications (user_id, created_at desc);

alter table public.notifications enable row level security;
drop policy if exists "notifications own" on public.notifications;
create policy "notifications own" on public.notifications
  for select to authenticated using (user_id = auth.uid());
drop policy if exists "notifications mark read" on public.notifications;
create policy "notifications mark read" on public.notifications
  for update to authenticated using (user_id = auth.uid()) with check (user_id = auth.uid());
drop policy if exists "notifications clear" on public.notifications;
create policy "notifications clear" on public.notifications
  for delete to authenticated using (user_id = auth.uid());
-- Only the read flag can be changed.
revoke update on public.notifications from authenticated;
grant update (read) on public.notifications to authenticated;

create or replace function public.notify(
  p_user uuid, p_type text, p_actor uuid, p_event uuid, p_body text
)
returns void
language sql security definer set search_path = ''
as $$
  insert into public.notifications (user_id, type, actor_id, event_id, body)
  values (p_user, p_type, p_actor, p_event, p_body);
$$;
revoke execute on function public.notify(uuid, text, uuid, uuid, text) from public, anon, authenticated;

create or replace function public.profile_name(p uuid)
returns text
language sql stable security definer set search_path = ''
as $$ select coalesce((select name from public.profiles where id = p), 'Someone'); $$;

create or replace function public.on_friendship_change()
returns trigger
language plpgsql security definer set search_path = ''
as $$
begin
  if tg_op = 'INSERT' then
    perform public.notify(new.addressee_id, 'friend_request', new.requester_id, null,
      public.profile_name(new.requester_id) || ' sent you a friend request');
  elsif tg_op = 'UPDATE' and old.status = 'pending' and new.status = 'accepted' then
    perform public.notify(new.requester_id, 'friend_accepted', new.addressee_id, null,
      public.profile_name(new.addressee_id) || ' accepted your friend request');
  end if;
  return new;
end;
$$;
drop trigger if exists friendship_notify on public.friendships;
create trigger friendship_notify
  after insert or update on public.friendships
  for each row execute function public.on_friendship_change();

create or replace function public.on_group_join()
returns trigger
language plpgsql security definer set search_path = ''
as $$
declare
  ev record;
begin
  select e.id, e.host_id, e.title into ev
  from public.event_groups g join public.events e on e.id = g.event_id
  where g.id = new.group_id;
  if ev.host_id is not null and ev.host_id <> new.user_id then
    perform public.notify(ev.host_id, 'event_joined', new.user_id, ev.id,
      public.profile_name(new.user_id) || ' joined ' || ev.title);
  end if;
  return new;
end;
$$;
drop trigger if exists group_join_notify on public.group_members;
create trigger group_join_notify
  after insert on public.group_members
  for each row execute function public.on_group_join();

create or replace function public.on_direct_message()
returns trigger
language plpgsql security definer set search_path = ''
as $$
begin
  perform public.notify(new.recipient_id, 'direct_message', new.sender_id, null,
    public.profile_name(new.sender_id) || ': ' || left(new.body, 80));
  return new;
end;
$$;
drop trigger if exists direct_message_notify on public.direct_messages;
create trigger direct_message_notify
  after insert on public.direct_messages
  for each row execute function public.on_direct_message();

-- ---------------------------------------------------------------------------
-- Realtime
-- ---------------------------------------------------------------------------

do $$
declare
  t text;
begin
  foreach t in array array['messages', 'events', 'group_members', 'friendships', 'direct_messages', 'notifications'] loop
    if not exists (
      select 1 from pg_publication_tables
      where pubname = 'supabase_realtime' and schemaname = 'public' and tablename = t
    ) then
      execute format('alter publication supabase_realtime add table public.%I', t);
    end if;
  end loop;
end;
$$;
