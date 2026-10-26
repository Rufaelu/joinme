// End-to-end check of the Supabase backend (schema, RLS, join_event, ratings).
//
// Run:  dart run tool/smoke_test.dart
//
// Signs up three throwaway users and creates two short (minutes-long) test
// events, which simply end and drop off the map. Requires "Confirm email" to be off in Supabase Auth settings.
// ignore_for_file: depend_on_referenced_packages, avoid_print
import 'dart:async';
import 'dart:io';

import 'package:supabase/supabase.dart';

import 'package:joinme/config/supabase_config.dart';

var _passed = 0;
const rls = 'row-level security';

void check(bool ok, String what) {
  if (!ok) {
    print('FAIL: $what');
    exit(1);
  }
  _passed++;
  print('ok   $what');
}

Future<void> expectError(Future<dynamic> Function() f, String what, {String? contains}) async {
  try {
    await f();
  } catch (e) {
    final text = e.toString();
    check(contains == null || text.contains(contains), '$what (got: ${text.split('\n').first})');
    return;
  }
  check(false, '$what — expected an error but it succeeded');
}

Future<SupabaseClient> newUser(String name, String tag) async {
  final client = SupabaseClient(
    supabaseUrl,
    supabaseKey,
    authOptions: const AuthClientOptions(autoRefreshToken: false),
  );
  final domain = Platform.environment['SMOKE_DOMAIN'] ?? 'example.com';
  final email = 'joinme.smoke.$tag.${name.toLowerCase()}@$domain';
  final res = await client.auth.signUp(email: email, password: 'smoke-test-pw-1', data: {'name': '$name Smoke'});
  if (res.session == null) {
    print('FAIL: sign-up for $email returned no session. Turn off "Confirm email" in Supabase Auth.');
    exit(1);
  }
  return client;
}

String uid(SupabaseClient c) => c.auth.currentUser!.id;

Future<String> createEvent(SupabaseClient c, {required int groupSize, required Duration endsIn}) async {
  final now = DateTime.now().toUtc();
  final row = await c.from('events').insert({
    'title': 'Smoke test event',
    'category': 'sports',
    'location_name': 'Meskel Square',
    'lat': 9.01,
    'lng': 38.761,
    'starts_at': now.subtract(const Duration(minutes: 1)).toIso8601String(),
    'ends_at': now.add(endsIn).toIso8601String(),
    'group_size': groupSize,
  }).select('id').single();
  return row['id'] as String;
}

Future<String> join(SupabaseClient c, String eventId) async =>
    (await c.rpc('join_event', params: {'p_event_id': eventId})) as String;

Future<int> groupNumber(SupabaseClient c, String groupId) async =>
    ((await c.from('event_groups').select('number').eq('id', groupId).single())['number'] as num).toInt();

Future<void> main() async {
  final tag = DateTime.now().millisecondsSinceEpoch.toString();
  final a = await newUser('Alice', tag);
  final b = await newUser('Bob', tag);
  final c = await newUser('Cara', tag);
  check(true, 'signed up 3 users');

  final profile = await a.from('profiles').select('name').eq('id', uid(a)).single();
  check(profile['name'] == 'Alice Smoke', 'profile row created from sign-up name');

  // --- Event 1: group size 2, ends in ~75s
  final ev1 = await createEvent(a, groupSize: 2, endsIn: const Duration(seconds: 75));
  final feed = await b.from('event_feed').select().eq('id', ev1).single();
  check(feed['member_count'] == 1 && feed['group_count'] == 1 && feed['host_name'] == 'Alice Smoke',
      'event_feed shows new event with host in group 1');
  check(feed['host_reputation'] == null, 'new host has no reputation yet');

  final aGroup = await join(a, ev1);
  check(await groupNumber(a, aGroup) == 1, 'host is already in group 1 (join returns it)');

  final bGroup = await join(b, ev1);
  check(bGroup == aGroup, 'second person joins group 1');
  final cGroup = await join(c, ev1);
  check(cGroup != aGroup && await groupNumber(c, cGroup) == 2, 'third person opens group 2 when group 1 is full');
  check(await join(b, ev1) == bGroup, 'joining twice returns the same group');

  // --- Concurrency: event 2, host holds one slot of group 1, B and C race for the other.
  final ev2 = await createEvent(a, groupSize: 2, endsIn: const Duration(minutes: 3));
  final raced = await Future.wait([join(b, ev2), join(c, ev2)]);
  final nums = [await groupNumber(b, raced[0]), await groupNumber(c, raced[1])]..sort();
  check(nums[0] == 1 && nums[1] == 2, 'concurrent joins: one gets the last slot, the other gets a new group');
  final ev2Members = await a.from('group_members').select('group_id, event_groups!inner(event_id)').eq('event_groups.event_id', ev2);
  check(ev2Members.length == 3, 'no duplicate memberships after the race');

  // --- Messages and realtime
  final received = Completer<void>();
  final sub = b.from('messages').stream(primaryKey: ['id']).eq('group_id', aGroup).listen((rows) {
    if (rows.any((r) => r['body'] == 'hello from alice') && !received.isCompleted) received.complete();
  });
  await Future<void>.delayed(const Duration(seconds: 2));
  await a.from('messages').insert({'group_id': aGroup, 'body': 'hello from alice'});
  await received.future.timeout(const Duration(seconds: 10), onTimeout: () {
    check(false, 'realtime: group mate receives message live');
  });
  check(true, 'realtime: group mate receives message live');
  await sub.cancel();

  final cSees = await c.from('messages').select().eq('group_id', aGroup);
  check(cSees.isEmpty, 'people outside the group cannot read its messages');
  await expectError(() => c.from('messages').insert({'group_id': aGroup, 'body': 'sneaky'}),
      'people outside the group cannot post in it', contains: rls);

  // --- Host cannot move times or delete once started
  final moved = await a
      .from('events')
      .update({'ends_at': DateTime.now().toUtc().subtract(const Duration(minutes: 1)).toIso8601String()})
      .eq('id', ev2)
      .select();
  check(moved.isEmpty, 'host cannot change event times (would open rating early)');
  final deleted = await a.from('events').delete().eq('id', ev2).select();
  check(deleted.isEmpty, 'host cannot delete an event that has started');

  // --- Ratings
  Future<dynamic> rate(SupabaseClient who, String eventId, int eventScore, int? hostScore, Map<String, int> peers) =>
      who.rpc('submit_ratings', params: {
        'p_event_id': eventId,
        'p_event_score': eventScore,
        'p_host_score': hostScore,
        'p_peers': [for (final e in peers.entries) {'ratee_id': e.key, 'score': e.value}],
      });

  await expectError(() => rate(b, ev1, 5, 5, {}), 'cannot rate before the event ends', contains: rls);

  final ends = DateTime.parse(feed['ends_at'] as String);
  final wait = ends.difference(DateTime.now().toUtc()) + const Duration(seconds: 3);
  if (!wait.isNegative) {
    print('...  waiting ${wait.inSeconds}s for the event to end');
    await Future<void>.delayed(wait);
  }

  await expectError(() => join(b, ev1), 'cannot join an ended event', contains: 'This event has ended');

  await rate(b, ev1, 5, 4, {});
  check(true, 'member rates the event and host after it ends');
  await expectError(() => rate(b, ev1, 3, 3, {}), 'cannot rate the same event twice', contains: '23505');
  await rate(c, ev1, 3, 2, {});
  check(true, 'member of group 2 rates the event and host');

  await expectError(() => rate(a, ev1, 5, 5, {}), 'host cannot rate themselves as host', contains: rls);
  await expectError(() => rate(a, ev1, 5, null, {uid(b): 9}), 'out-of-range peer score is rejected', contains: '23514');
  final aRows = await a.from('event_ratings').select().eq('event_id', ev1).eq('rater_id', uid(a));
  check(aRows.isEmpty, 'a failed submit saves nothing, so it can be retried');
  await rate(a, ev1, 5, null, {uid(b): 5});
  check(true, 'host rates the event and a group mate in one submit');

  await expectError(() => b.from('user_ratings').insert({'event_id': ev1, 'ratee_id': uid(a), 'score': 1}),
      'host cannot be double-rated as a group mate', contains: rls);
  await expectError(() => b.from('user_ratings').insert({'event_id': ev1, 'ratee_id': uid(c), 'score': 1}),
      'cannot rate someone from a different group', contains: rls);
  await expectError(() => b.from('user_ratings').insert({'event_id': ev1, 'ratee_id': uid(b), 'score': 5}),
      'cannot rate yourself', contains: rls);

  // --- Privacy: only averages are public
  final othersRatings = await c.from('user_ratings').select().eq('ratee_id', uid(b));
  check(othersRatings.isEmpty, 'cannot read who rated someone else');
  final bEventRows = await b.from('event_ratings').select().eq('event_id', ev1);
  check(bEventRows.length == 1, 'can only read your own event ratings');

  final statsA = await b.from('profile_stats').select().eq('id', uid(a)).single();
  check((statsA['reputation'] as num).toDouble() == 3.0 && statsA['rating_count'] == 2,
      'host reputation = average of host scores (4 and 2 → 3.0, 2 ratings)');
  check(statsA['events_hosted'] == 2, 'host has 2 events hosted');
  final statsB = await c.from('profile_stats').select().eq('id', uid(b)).single();
  check((statsB['reputation'] as num).toDouble() == 5.0 && statsB['events_attended'] == 1,
      'group mate reputation 5.0 and 1 event attended');
  final feedAfter = await c.from('event_feed').select('host_reputation').eq('id', ev1).single();
  check((feedAfter['host_reputation'] as num).toDouble() == 3.0, 'event feed shows the host reputation');

  // --- Leave group
  await c.from('group_members').delete().eq('group_id', raced[1]).eq('user_id', uid(c));
  final cStill = await c.from('group_members').select().eq('group_id', raced[1]).eq('user_id', uid(c));
  check(cStill.isEmpty, 'a member can leave their group');

  // --- Deleting before start is allowed (the two test events above just end and drop off the map)
  final now = DateTime.now().toUtc();
  final future = await a.from('events').insert({
    'title': 'Smoke test future event',
    'category': 'chill',
    'location_name': 'Meskel Square',
    'lat': 9.01,
    'lng': 38.761,
    'starts_at': now.add(const Duration(hours: 1)).toIso8601String(),
    'ends_at': now.add(const Duration(hours: 2)).toIso8601String(),
    'group_size': 4,
  }).select('id').single();
  final gone = await a.from('events').delete().eq('id', future['id']).select();
  check(gone.length == 1, 'host can delete an event before it starts');

  print('\nALL CHECKS PASSED ($_passed)');
  exit(0);
}
