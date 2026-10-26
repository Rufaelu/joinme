# JoinMe Supabase Backend Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Turn the JoinMe Flutter prototype into a working app backed by Supabase: real accounts, real events on the map, auto-splitting group chats in real time, and post-event ratings that build reputation.

**Architecture:** One SQL file (`supabase/schema.sql`) defines tables, row-level security, and two database functions (`join_event`, plus a trigger that creates group 1 for each new event). The Flutter app talks to Supabase through four thin service classes; `AppState` keeps its existing string-based navigation and gains the signed-in profile and live event list. Screens keep their current look; mock data is replaced only in the core loop.

**Tech Stack:** Flutter 3.41 / Dart 3.11, `supabase_flutter` ^2, Postgres + Supabase Auth/Realtime, existing `provider`, `flutter_map`, `geolocator`.

**Spec:** Approved in chat on 2026-10-26 (summarized here):
- Email/password accounts; profile = name, avatar (initials), bio, reputation.
- Event = title, category, description, location (name/lat/lng), start, end, group size, host.
- Joining puts you in the lowest-numbered group with room; if all are full a new group is created. Done atomically in the database. Host starts in group 1.
- Group chat is live (Supabase Realtime). Only group members can read/send.
- After an event's end time: each member rates the event (1–5) and the host (1–5), and each other person in their group (1–5). Reputation = average of all person ratings received (as host via `host_score`, or as group member). Shown on profiles, event detail, chat.
- Out of scope: friends, direct messages, notifications (stay mock), push notifications.

## Global Constraints

- Supabase URL: `https://mrobcgdcelpxvbkeasfz.supabase.co`; publishable key: `sb_publishable_WGf8qe_vbkD48ZNE1rxOMQ_HS6LXop7` (public; safe to commit).
- Never put a service-role/secret key in the repo or app.
- Keep the existing UI style (GlassContainer, category colors, flutter_animate) and the `AppState.navigateTo(String)` navigation; no router rewrite.
- Ratings are integers 1–5. Group size is 2–50. Message body 1–2000 chars.
- Reputation displays as `4.6` with a star and rating count; users with no ratings show `New`.
- Custom category keeps current behavior (saved as `creative`).

## Review Focus

- Two people join the last slot of a group at the same moment → exactly one gets it, the other lands in a new group (row lock in `join_event`). Covered by integration test T7.
- Joining an event you are already in (tap Join twice, or host taps Join) → returns your existing group, no duplicate membership. Integration test T7.
- Rating before the event has ended, rating yourself, or rating someone from a different group → rejected by RLS; UI hides the button. Integration test T7 + unit test `canRate`.
- Event whose end time has passed → no longer shown on the map, cannot be joined. `join_event` raises; map query filters `ends_at > now()`. Integration test T7.
- Sign-up when Supabase "Confirm email" is on → no session returned; app must show "Check your email to confirm" instead of hanging. Handled in Task 3.

---

### Task 1: Database schema, RLS, and functions

**Files:**
- Create: `supabase/schema.sql`

**Interfaces:**
- Produces tables: `profiles(id uuid pk→auth.users, name text, bio text, created_at)`; `events(id uuid, host_id uuid default auth.uid(), title, category, description, location_name, lat float8, lng float8, starts_at timestamptz, ends_at timestamptz, group_size int, created_at)`; `event_groups(id uuid, event_id, number int, unique(event_id,number))`; `group_members(group_id, user_id, joined_at, pk(group_id,user_id))`; `messages(id bigint identity, group_id, sender_id default auth.uid(), body, created_at)`; `event_ratings(event_id, rater_id default auth.uid(), event_score, host_score, pk(event_id,rater_id))`; `user_ratings(event_id, rater_id default auth.uid(), ratee_id, score, pk(event_id,rater_id,ratee_id))`.
- Produces views (`security_invoker = on`): `profile_stats(id, name, bio, reputation numeric null, rating_count int, events_hosted int, events_attended int)`; `event_feed(...events columns, host_name, host_reputation, host_rating_count, member_count, group_count)`.
- Produces RPC `join_event(p_event_id uuid) returns uuid` (group id).
- Trigger `on_auth_user_created` inserts profile with `name = raw_user_meta_data->>'name'` (fallback: email local part). Trigger `on_event_created` creates group 1 and adds host.
- Helper `is_group_member(g uuid) returns bool` (security definer) used by message policies; `shares_group(e uuid, a uuid, b uuid) returns bool` for user ratings.
- `messages` added to publication `supabase_realtime`; `events` and `group_members` too (for map refresh).

- [ ] **Step 1: Write `supabase/schema.sql`** — idempotent where practical (`create table if not exists`, `create or replace function`, `drop policy if exists` before each `create policy`). `join_event` algorithm:

```sql
-- lock the event row so concurrent joins serialize
select * into ev from events where id = p_event_id for update;
if not found then raise exception 'Event not found'; end if;
if ev.ends_at <= now() then raise exception 'This event has ended'; end if;
-- already a member? return that group
select gm.group_id into gid from group_members gm join event_groups g on g.id = gm.group_id
  where g.event_id = p_event_id and gm.user_id = auth.uid();
if gid is not null then return gid; end if;
-- first group with room
select g.id into gid from event_groups g
  where g.event_id = p_event_id
    and (select count(*) from group_members where group_id = g.id) < ev.group_size
  order by g.number limit 1;
if gid is null then
  insert into event_groups(event_id, number)
  values (p_event_id, coalesce((select max(number) from event_groups where event_id = p_event_id), 0) + 1)
  returning id into gid;
end if;
insert into group_members(group_id, user_id) values (gid, auth.uid());
return gid;
```

RLS: everything readable by `authenticated` except `messages` (members only). Writes: `profiles` update own; `events` insert/update/delete where `host_id = auth.uid()`; `group_members` delete own (leave); no direct insert on `event_groups`/`group_members` (functions are `security definer`). `messages` insert where `sender_id = auth.uid() and is_group_member(group_id)`. `event_ratings` insert where `rater_id = auth.uid()`, rater is in a group of that event, event `ends_at < now()`. `user_ratings` insert where `rater_id = auth.uid()`, `ratee_id <> rater_id`, `shares_group(event_id, rater_id, ratee_id)`, event ended. Check constraints on scores, group size, title non-empty, body length, `ends_at > starts_at`.

Reputation in `profile_stats`: average over the union of `user_ratings.score where ratee_id = p.id` and `event_ratings.host_score` for events where `host_id = p.id`, rounded to 1 decimal; `rating_count` = size of that union.

- [ ] **Step 2: User pastes file into Supabase SQL Editor and runs it** — expected: "Success. No rows returned". Also ask the user to turn off Authentication → Providers → Email → "Confirm email" for the demo.
- [ ] **Step 3: Commit** `git add supabase/schema.sql && git commit -m "feat: supabase schema, RLS, join_event"`

### Task 2: Supabase setup and models

**Files:**
- Modify: `pubspec.yaml` (add `supabase_flutter: ^2.8.0`)
- Create: `lib/config/supabase_config.dart` — `const supabaseUrl`, `const supabaseKey`.
- Create: `lib/models/models.dart` — move `EventCategory`, `EventHost`, `EventLocation`, `JoinMeEvent` here from `mock_data.dart`; add `Profile`, `EventGroup`, `ChatMessage`.
- Modify: `lib/data/mock_data.dart` — delete `mockEvents` and the moved classes; keep `Friend`, `mockFriends`; delete `currentUser` (Task 6 replaces its uses). Re-export `models.dart` so existing imports keep compiling.
- Modify: `lib/main.dart` — `await Supabase.initialize(url:, anonKey:)` before `runApp`.
- Test: `test/models_test.dart`; replace `test/widget_test.dart` (counter test is dead) with nothing (delete).

**Interfaces:**
- `JoinMeEvent` fields: `id, title, category, description?, host (EventHost), location (EventLocation), startsAt, endsAt, groupSize, memberCount, groupCount`; getters `int get timeRemaining` (minutes until start, min 0), `int get duration` (minutes), `bool get hasEnded` (`DateTime.now()` ≥ endsAt), `int get participants => memberCount`, `int get maxParticipants => groupSize * groupCount`. `factory JoinMeEvent.fromFeed(Map<String, dynamic>)` parses an `event_feed` row.
- `EventHost(id, name, avatar, reputation double?, ratingCount int)`; `avatar` = initials from name. Remove `reliability`.
- `Profile(id, name, bio?, reputation double?, ratingCount, eventsHosted, eventsAttended)`; `factory Profile.fromStats(Map)`; `String get initials`.
- `EventGroup(id, eventId, number, members List<Profile-lite: id,name>)`.
- `ChatMessage(id int, groupId, senderId, senderName, body, createdAt)`; `factory ChatMessage.fromMap(Map, {required String senderName})`.
- Top-level `String initialsOf(String name)` and `String formatReputation(double? rep)` → `'New'` or `'4.6'`.

- [ ] **Step 1: Write failing tests** in `test/models_test.dart`:
  - `initialsOf('Rufael Melese') == 'RM'`, `initialsOf('edna') == 'E'`, `initialsOf('  ') == '?'`.
  - `formatReputation(null) == 'New'`, `formatReputation(4.56) == '4.6'`.
  - `JoinMeEvent.fromFeed` on a sample row (starts in +30 min, 90 min long, group_size 6, member_count 7, group_count 2, host_reputation null) → `timeRemaining` in 29..30, `duration == 90`, `maxParticipants == 12`, `participants == 7`, `host.reputation == null`, `hasEnded == false`.
  - Row with `ends_at` in the past → `hasEnded == true`, `timeRemaining == 0`.
- [ ] **Step 2:** `flutter test test/models_test.dart` → FAIL (missing file/classes).
- [ ] **Step 3:** Implement models, config, init; `flutter pub get`.
- [ ] **Step 4:** `flutter test test/models_test.dart` → PASS. (`flutter analyze` will show errors in screens until Tasks 3–6; that's expected.)
- [ ] **Step 5: Commit.**

### Task 3: Auth (login/signup/logout, session restore)

**Files:**
- Create: `lib/services/auth_service.dart`
- Modify: `lib/providers/app_state.dart`, `lib/screens/login_signup_screen.dart:33-35` (`_handleSubmit`), `lib/screens/profile_screen.dart:183` (logout).

**Interfaces:**
- `AuthService`: `Future<AuthResult> signUp({required String name, required String email, required String password})`, `Future<void> signIn({email, password})`, `Future<void> signOut()`, `String? get userId`. `enum AuthResult { signedIn, needsEmailConfirmation }`. Errors surface as `AuthException` messages.
- `AppState`: `Profile? me`, `Future<void> loadMe()` (reads `profile_stats` for current user), constructor sets initial screen to `'map'` if a session exists else `'login'`, and listens to `onAuthStateChange` to reset to `'login'` on sign-out.

- [ ] **Step 1:** Implement. Login screen: validate non-empty email, password ≥ 6, name required on signup; show spinner on the submit button while busy; errors via `ScaffoldMessenger` SnackBar; signup success → `'onboarding'`, login success → `'map'`; `needsEmailConfirmation` → SnackBar "Check your email to confirm your account, then sign in." and switch to login tab. Social buttons (Google/Apple) show SnackBar "Coming soon".
- [ ] **Step 2: Verify** `flutter analyze lib/screens/login_signup_screen.dart lib/services lib/providers` → no errors.
- [ ] **Step 3: Commit.**

### Task 4: Events on the map and creating events

**Files:**
- Create: `lib/services/event_service.dart`
- Modify: `lib/providers/app_state.dart` (replace mock `_events`, `addEvent`), `lib/screens/map_screen.dart` (marker/card fields, search, refresh), `lib/screens/create_event_screen.dart` (start time picker, submit to Supabase).

**Interfaces:**
- `EventService`: `Future<List<JoinMeEvent>> fetchActive()` (`event_feed` where `ends_at > now`, order `starts_at`), `Future<JoinMeEvent> fetchOne(String id)`, `Future<String> create(EventDraft d)` returns id, `RealtimeChannel subscribeChanges(void Function() onChange)` on `events` + `group_members`.
- `EventDraft(title, category, description?, locationName, lat, lng, startsAt, durationMinutes, groupSize)` with `String? validate(DateTime now)` → error text or null: empty title → `'Add a title'`; no location → `'Pick a location on the map'`; groupSize outside 2–50 → `'Group size must be 2–50'`; startsAt earlier than now − 5 min → `'Start time is in the past'`.
- `AppState`: `List<JoinMeEvent> events`, `Future<void> refreshEvents()`, `Future<void> createEvent(EventDraft)`; subscribes on first `refreshEvents`, unsubscribes on sign-out.

- [ ] **Step 1: Failing tests** in `test/event_draft_test.dart` for each `validate` rule above plus a valid draft returning `null`.
- [ ] **Step 2:** `flutter test test/event_draft_test.dart` → FAIL.
- [ ] **Step 3:** Implement `EventDraft`, `EventService`, AppState wiring. Map: load on init, markers from `appState.events`, preview card shows `formatReputation`, `participants/maxParticipants`, "Starts in Xm" or "Happening now"; search box filters `events` by title/location (case-insensitive); zap icon → `refreshEvents()`; no auto-select of `events[0]` when the list is empty. Create screen: add start-time picker next to date (default: now + 30 min rounded to 5), label "Max People" → "People per group" (default 6), button disabled with reason shown under it when `validate` fails, spinner while saving, on success → `refreshEvents()` then navigate to `'event'` with the new id.
- [ ] **Step 4:** `flutter test test/event_draft_test.dart` → PASS; `flutter analyze lib/screens/map_screen.dart lib/screens/create_event_screen.dart` → no errors.
- [ ] **Step 5: Commit.**

### Task 5: Event detail, joining, groups, live group chat

**Files:**
- Create: `lib/services/chat_service.dart`
- Modify: `lib/providers/app_state.dart` (`selectedGroupId`, `navigateTo(..., groupId:)`), `lib/main.dart` (`'chat'` passes `groupId`), `lib/screens/event_detail_screen.dart`, `lib/screens/group_chat_screen.dart`, `lib/screens/messages_screen.dart` (Groups tab real, Direct tab stays mock).

**Interfaces:**
- `ChatService`: `Future<List<EventGroup>> groupsFor(String eventId)` (groups + member id/name), `Future<String> joinEvent(String eventId)` → RPC `join_event`, `Future<void> leaveGroup(String groupId)`, `Stream<List<ChatMessage>> messages(String groupId)` (`.stream(primaryKey:['id']).eq('group_id', groupId).order('created_at')`, sender names resolved from a cached `profiles` lookup), `Future<void> send(String groupId, String body)`, `Future<List<MyGroup>> myGroups()` where `MyGroup(groupId, groupNumber, eventId, eventTitle, category, memberCount, lastMessage?, lastAt?)`.
- `AppState.navigateTo(String screen, {String? eventId, String? groupId, Map<String,dynamic>? friendData})`.

- [ ] **Step 1:** Event detail loads `fetchOne` + `groupsFor` (FutureBuilder/State), shows real host name/initials/reputation, "Starts in"/"Happening now"/"Ended", distance from current location if available else omit, a "Groups" section listing `Group N · members/groupSize` with member initials. Button states: not a member & not ended → "Join Event" (calls `joinEvent`, then `navigateTo('chat', eventId, groupId)`); member → "Open Group Chat"; ended & member → "Rate Event" (Task 6 screen); ended & not member → disabled "Event ended". Errors → SnackBar with the Postgres message.
- [ ] **Step 2:** Group chat: header "Event title · Group N", member count; messages from stream, own messages right-aligned using `senderId == me.id`, sender initials avatar, `HH:mm` local time; auto-scroll on new messages; send trims, ignores empty, disables while sending; phone/video icons removed; menu with "Leave group" (confirm dialog → `leaveGroup` → back to event). Back arrow → `'event'`.
- [ ] **Step 3:** Messages screen Groups tab → `myGroups()`; tap → chat with that group. Empty state text kept.
- [ ] **Step 4: Verify** `flutter analyze` → no errors in these files.
- [ ] **Step 5: Commit.**

### Task 6: Ratings, reputation, real profile

**Files:**
- Create: `lib/services/rating_service.dart`, `lib/screens/rate_event_screen.dart`
- Modify: `lib/main.dart` (`'rate'` route), `lib/screens/profile_screen.dart`, `lib/screens/profile_edit_screen.dart`, `lib/screens/event_detail_screen.dart` (Rate button target).

**Interfaces:**
- `RatingService`: `Future<bool> hasRated(String eventId)`, `Future<void> submit({required String eventId, required int eventScore, required int hostScore, required Map<String,int> peerScores})` — inserts `event_ratings` then `user_ratings` rows in one `insert([...])`; `Future<List<PastEvent>> myPastEvents()` (events I hosted or joined with `ends_at < now`, newest first) where `PastEvent(eventId, title, category, endedAt, rated bool)`.
- Pure helper in `models.dart`: `bool canRate({required DateTime endsAt, required DateTime now, required bool isMember, required bool alreadyRated})`.
- `AppState.updateProfile({required String name, String? bio})`.

- [ ] **Step 1: Failing tests** `test/models_test.dart` add: `canRate` true only when `now` after `endsAt`, member, not rated; false for each violated condition.
- [ ] **Step 2:** `flutter test` → FAIL.
- [ ] **Step 3:** Implement. Rate screen: event 1–5 stars, host 1–5 stars (hidden when I am the host), each other member of my group with 1–5 stars (excluding me; host excluded from peers if already rated via host stars), Submit disabled until event+host stars chosen; peers optional. After submit → SnackBar "Thanks for rating!" → `'profile'`. Profile: name, initials, `formatReputation(me.reputation)` with `(N ratings)`, attended/hosted from `profile_stats`, past events list from `myPastEvents()` with a "Rate" chip on unrated ones, logout via `AuthService.signOut`. Profile edit: name + bio saved to `profiles`. Event detail and chat show host/peer reputation via `formatReputation`.
- [ ] **Step 4:** `flutter test` → PASS; `flutter analyze` → no errors project-wide.
- [ ] **Step 5: Commit.**

### Task 7: End-to-end verification against Supabase

**Files:**
- Create: `tool/smoke_test.dart` (plain Dart, uses `supabase` package via `supabase_flutter`'s dependency; run with `dart run tool/smoke_test.dart`).

- [ ] **Step 1:** Script signs up 3 throwaway users (`joinme.smoke+<ts>.<n>@example.com`), then asserts:
  - User A creates event with `group_size: 2`, starting now, ending in 1 min → `event_feed` shows it, A in group 1.
  - B `join_event` → group 1 (now full). C `join_event` → new group 2. B joins again → same group 1 id.
  - B and C call `join_event` concurrently on a fresh size-2 event where A holds 1 slot → one gets group 1, the other group 2.
  - C cannot read group 1 messages (empty result); B can send and read.
  - Rating before end → error. After waiting until end (≤ 70 s): B rates event+host and A; B rating C (different group) → error; B rating self → error.
  - `profile_stats` for A shows reputation and `rating_count == 2`.
  - Joining the ended event → error "This event has ended".
  - Prints `ALL CHECKS PASSED` or the first failure.
- [ ] **Step 2:** Run it → `ALL CHECKS PASSED`. Fix schema/app on failure.
- [ ] **Step 3:** `flutter build apk --debug` (or `flutter run -d linux` if no Android SDK) → builds. Manual walk-through: sign up, create event via long-press, join from a second account, chat both ways, rate after end.
- [ ] **Step 4:** Update `README.md` (remove "frontend only" notice; add Supabase setup: run `supabase/schema.sql`, disable email confirm for testing). Commit.
