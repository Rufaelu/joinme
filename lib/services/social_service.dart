import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/social.dart';

/// Friends, direct messages and notifications.
class SocialService {
  SupabaseClient get _db => Supabase.instance.client;
  String get _me => _db.auth.currentUser!.id;

  // --- Friends -------------------------------------------------------------

  /// Everyone I'm connected to (friends + pending either way), with reputation.
  Future<List<Person>> connections() async {
    final me = _me;
    final rows = await _db.from('friendships').select('requester_id, addressee_id, status');
    if (rows.isEmpty) return [];
    final relationById = <String, FriendRelation>{
      for (final r in rows)
        (r['requester_id'] == me ? r['addressee_id'] : r['requester_id']) as String: relationFor(
          requesterId: r['requester_id'] as String,
          addresseeId: r['addressee_id'] as String,
          status: r['status'] as String,
          me: me,
        ),
    };
    final stats = await _db
        .from('profile_stats')
        .select('id, name, avatar_url, reputation, rating_count, deleted_at')
        .inFilter('id', relationById.keys.toList());
    return stats.map((s) => Person.fromStats(s, relation: relationById[s['id']]!)).toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
  }

  /// People whose name matches [query], marked with my relation to them.
  Future<List<Person>> searchPeople(String query) async {
    final q = query.trim();
    if (q.length < 2) return [];
    final rows = await _db
        .from('profile_stats')
        .select('id, name, avatar_url, reputation, rating_count, deleted_at')
        .ilike('name', '%${q.replaceAll('%', '').replaceAll('_', '')}%')
        .neq('id', _me)
        .isFilter('deleted_at', null)
        .limit(20);
    final known = {for (final p in await connections()) p.id: p.relation};
    return rows.map((r) => Person.fromStats(r, relation: known[r['id']] ?? FriendRelation.none)).toList();
  }

  Future<Person> person(String userId) async {
    final row = await _db
        .from('profile_stats')
        .select('id, name, avatar_url, reputation, rating_count, deleted_at')
        .eq('id', userId)
        .single();
    return Person.fromStats(row, relation: await relationWith(userId));
  }

  Future<FriendRelation> relationWith(String userId) async {
    final me = _me;
    final rows = await _db
        .from('friendships')
        .select('requester_id, addressee_id, status')
        .or('and(requester_id.eq.$me,addressee_id.eq.$userId),and(requester_id.eq.$userId,addressee_id.eq.$me)');
    if (rows.isEmpty) return FriendRelation.none;
    final r = rows.first;
    return relationFor(
      requesterId: r['requester_id'] as String,
      addresseeId: r['addressee_id'] as String,
      status: r['status'] as String,
      me: me,
    );
  }

  /// Sends a request (or accepts theirs). Returns the new relation.
  Future<FriendRelation> addFriend(String userId) async {
    final status = await _db.rpc('send_friend_request', params: {'p_user': userId}) as String;
    return status == 'accepted' ? FriendRelation.friends : FriendRelation.outgoing;
  }

  Future<void> respond(String requesterId, {required bool accept}) =>
      _db.rpc('respond_friend_request', params: {'p_requester': requesterId, 'p_accept': accept});

  /// Unfriend, or cancel a request I sent.
  Future<void> removeFriend(String userId) => _db.rpc('remove_friend', params: {'p_user': userId});

  // --- Direct messages -------------------------------------------------------

  Stream<List<DirectMessage>> directMessages(String friendId) {
    return _db
        .from('direct_messages')
        .stream(primaryKey: ['id'])
        .eq('pair_key', pairKey(_me, friendId))
        .order('created_at', ascending: true)
        .map((rows) => rows.map(DirectMessage.fromMap).toList());
  }

  Future<void> sendDirect(String friendId, String body) =>
      _db.from('direct_messages').insert({'recipient_id': friendId, 'body': body.trim()});

  /// One entry per friend: the latest message, newest chats first.
  Future<List<DmThread>> threads() async {
    final friends = (await connections()).where((p) => p.relation == FriendRelation.friends).toList();
    if (friends.isEmpty) return [];
    final recent = await _db
        .from('direct_messages')
        .select('sender_id, recipient_id, body, created_at')
        .order('created_at', ascending: false)
        .limit(300);
    final me = _me;
    final latest = <String, Map<String, dynamic>>{};
    for (final m in recent) {
      final other = (m['sender_id'] == me ? m['recipient_id'] : m['sender_id']) as String;
      latest.putIfAbsent(other, () => m);
    }
    final threads = friends.map((f) {
      final m = latest[f.id];
      return DmThread(
        friend: f,
        lastMessage: m?['body'] as String?,
        lastAt: m == null ? null : DateTime.parse(m['created_at'] as String).toLocal(),
      );
    }).toList();
    threads.sort((a, b) {
      if (a.lastAt == null && b.lastAt == null) return a.friend.name.compareTo(b.friend.name);
      if (a.lastAt == null) return 1;
      if (b.lastAt == null) return -1;
      return b.lastAt!.compareTo(a.lastAt!);
    });
    return threads;
  }

  // --- Notifications ---------------------------------------------------------

  /// Live list of my latest notifications, newest first.
  Stream<List<AppNotification>> notifications() {
    return _db
        .from('notifications')
        .stream(primaryKey: ['id'])
        .eq('user_id', _me)
        .order('created_at', ascending: false)
        .limit(50)
        .map((rows) => rows.map(AppNotification.fromMap).toList());
  }

  Future<void> markAllRead() =>
      _db.from('notifications').update({'read': true}).eq('user_id', _me).eq('read', false);

  /// Marks message notifications from [friendId] read (when their chat is opened).
  Future<void> markChatRead(String friendId) => _db
      .from('notifications')
      .update({'read': true})
      .eq('user_id', _me)
      .eq('actor_id', friendId)
      .eq('type', 'direct_message')
      .eq('read', false);

  Future<void> clearAll() => _db.from('notifications').delete().eq('user_id', _me);
}
