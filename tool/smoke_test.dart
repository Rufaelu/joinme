// End-to-end check of the Supabase backend (schema, RLS, join_event, ratings).
//
// Run:  dart run tool/smoke_test.dart
//
// Signs up three throwaway users and creates two short (minutes-long) test
// events, which simply end and drop off the map. Requires "Confirm email" to be off in Supabase Auth settings.
// ignore_for_file: depend_on_referenced_packages, avoid_print
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

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
    authOptions: const AuthClientOptions(autoRefreshToken: false, authFlowType: AuthFlowType.implicit),
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
  // Give the live connection time to join before sending.
  await Future<void>.delayed(const Duration(seconds: 6));
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

  // --- Friends, direct messages, notifications
  final found = await a.from('profile_stats').select('id').ilike('name', '%Bob Smoke%').eq('id', uid(b));
  check(found.length == 1, 'people search finds other users by name');

  await expectError(() => b.from('direct_messages').insert({'recipient_id': uid(a), 'body': 'hi stranger'}),
      'cannot message someone who is not a friend', contains: rls);

  check(await a.rpc('send_friend_request', params: {'p_user': uid(b)}) == 'pending', 'friend request sent');
  check(await a.rpc('send_friend_request', params: {'p_user': uid(b)}) == 'pending', 'sending twice does not duplicate');
  await expectError(() => a.rpc('send_friend_request', params: {'p_user': uid(a)}), 'cannot friend yourself',
      contains: 'cannot add yourself');
  final cSeesFriendship = await c.from('friendships').select();
  check(cSeesFriendship.isEmpty, "others can't see who is friends with whom");

  final bNotes = await b.from('notifications').select('type, actor_id').eq('type', 'friend_request');
  check(bNotes.length == 1 && bNotes.first['actor_id'] == uid(a), 'recipient gets a friend request notification');

  await b.rpc('respond_friend_request', params: {'p_requester': uid(a), 'p_accept': true});
  final aAccepted = await a.from('notifications').select().eq('type', 'friend_accepted').eq('actor_id', uid(b));
  check(aAccepted.length == 1, 'requester is notified when accepted');
  check(await b.rpc('are_friends', params: {'a': uid(a), 'b': uid(b)}) == true, 'they are now friends');
  check(await b.rpc('send_friend_request', params: {'p_user': uid(a)}) == 'accepted', 'adding an existing friend is harmless');

  final aJoined = await a.from('notifications').select().eq('type', 'event_joined');
  check(aJoined.isNotEmpty, 'host is notified when someone joins their event');

  final dmKey = uid(a).compareTo(uid(b)) <= 0 ? '${uid(a)}:${uid(b)}' : '${uid(b)}:${uid(a)}';
  final dmReceived = Completer<void>();
  final dmSub = b.from('direct_messages').stream(primaryKey: ['id']).eq('pair_key', dmKey).listen((rows) {
    if (rows.any((r) => r['body'] == 'hey bob') && !dmReceived.isCompleted) dmReceived.complete();
  });
  await Future<void>.delayed(const Duration(seconds: 6));
  await a.from('direct_messages').insert({'recipient_id': uid(b), 'body': 'hey bob'});
  await dmReceived.future.timeout(const Duration(seconds: 10), onTimeout: () {
    check(false, 'direct message arrives live');
  });
  check(true, 'direct message arrives live');
  await dmSub.cancel();

  final cSeesDm = await c.from('direct_messages').select().eq('pair_key', dmKey);
  check(cSeesDm.isEmpty, "others can't read a direct chat");
  final dmNote = await b.from('notifications').select('body').eq('type', 'direct_message');
  check(dmNote.length == 1 && (dmNote.first['body'] as String).contains('hey bob'), 'recipient gets a message notification');

  await b.from('notifications').update({'read': true}).eq('user_id', uid(b));
  final unread = await b.from('notifications').select().eq('read', false);
  check(unread.isEmpty, 'notifications can be marked read');
  await expectError(() => b.from('notifications').update({'body': 'tampered'}).eq('user_id', uid(b)),
      'only the read flag of a notification can change', contains: '42501');
  await expectError(
      () => c.from('notifications').insert({'user_id': uid(b), 'type': 'friend_request', 'body': 'fake'}),
      "can't create notifications for others", contains: '42501');

  await a.rpc('remove_friend', params: {'p_user': uid(b)});
  await expectError(() => a.from('direct_messages').insert({'recipient_id': uid(b), 'body': 'still there?'}),
      'after unfriending, messaging is blocked', contains: rls);

  // --- Photos (Supabase Storage)
  final png = Uint8List.fromList(base64Decode(
      'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg=='));
  // Same as the app: a fresh file name each time, no overwrite.
  final ownPath = '${uid(a)}/avatar-smoke-$tag.png';
  await a.storage.from('avatars').uploadBinary(ownPath, png,
      fileOptions: const FileOptions(contentType: 'image/png'));
  final publicUrl = a.storage.from('avatars').getPublicUrl(ownPath);
  final fetched = await HttpClient().getUrl(Uri.parse(publicUrl)).then((r) => r.close());
  check(fetched.statusCode == 200, 'uploaded photo is publicly viewable by URL');
  await expectError(
      () => a.storage.from('avatars').uploadBinary('${uid(b)}/avatar-sneaky.png', png,
          fileOptions: const FileOptions(contentType: 'image/png')),
      "cannot upload into someone else's photo folder",
      contains: 'row-level security');
  await a.from('profiles').update({'avatar_url': publicUrl}).eq('id', uid(a));
  final aStats = await b.from('profile_stats').select('avatar_url').eq('id', uid(a)).single();
  check(aStats['avatar_url'] == publicUrl, 'profile photo shows up for other users');

  final coverRow = await a.from('events').insert({
    'title': 'Smoke test cover event',
    'category': 'creative',
    'location_name': 'Meskel Square',
    'lat': 9.01,
    'lng': 38.761,
    'starts_at': now.add(const Duration(hours: 1)).toIso8601String(),
    'ends_at': now.add(const Duration(hours: 2)).toIso8601String(),
    'group_size': 4,
    'image_url': publicUrl,
  }).select('id').single();
  final coverFeed = await b.from('event_feed').select('image_url, host_avatar_url').eq('id', coverRow['id']).single();
  check(coverFeed['image_url'] == publicUrl && coverFeed['host_avatar_url'] == publicUrl,
      'event feed carries cover image and host photo');
  await a.from('events').delete().eq('id', coverRow['id']);
  await a.storage.from('avatars').remove([ownPath]);

  print('\nALL CHECKS PASSED ($_passed)');
  exit(0);
}
