import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/models.dart';

class MyGroup {
  final String groupId;
  final int groupNumber;
  final String eventId;
  final String eventTitle;
  final String category;
  final DateTime endsAt;
  final int memberCount;
  final String? lastMessage;
  final DateTime? lastAt;

  MyGroup({
    required this.groupId,
    required this.groupNumber,
    required this.eventId,
    required this.eventTitle,
    required this.category,
    required this.endsAt,
    required this.memberCount,
    this.lastMessage,
    this.lastAt,
  });
}

class ChatService {
  SupabaseClient get _db => Supabase.instance.client;
  final Map<String, String> _names = {};
  final Map<String, String?> _avatars = {};

  String? avatarOf(String userId) => _avatars[userId];

  Future<List<EventGroup>> groupsFor(String eventId) async {
    final rows = await _db
        .from('event_groups')
        .select('id, event_id, number, group_members(user_id, joined_at, profiles(name, avatar_url, deleted_at))')
        .eq('event_id', eventId)
        .order('number');
    return rows.map((g) {
      final members = (g['group_members'] as List)
          .cast<Map<String, dynamic>>()
          .toList()
        ..sort((a, b) => (a['joined_at'] as String).compareTo(b['joined_at'] as String));
      return EventGroup(
        id: g['id'] as String,
        eventId: g['event_id'] as String,
        number: (g['number'] as num).toInt(),
        members: members.map((m) {
          final profile = m['profiles'] as Map<String, dynamic>?;
          final name = profile?['name'] as String? ?? 'Someone';
          final avatar = profile?['avatar_url'] as String?;
          final deleted = profile?['deleted_at'] != null;
          _names[m['user_id'] as String] = shownName(name, parseTime(profile?['deleted_at']));
          _avatars[m['user_id'] as String] = avatar;
          return GroupMember(id: m['user_id'] as String, name: name, avatarUrl: avatar, isDeleted: deleted);
        }).toList(),
      );
    }).toList();
  }

  /// Joins the first group with room (or a new one) and returns its id.
  Future<String> joinEvent(String eventId) async {
    final res = await _db.rpc('join_event', params: {'p_event_id': eventId});
    return res as String;
  }

  Future<void> leaveGroup(String groupId) async {
    final uid = _db.auth.currentUser!.id;
    await _db.from('group_members').delete().eq('group_id', groupId).eq('user_id', uid);
  }

  Future<void> _resolveNames(Iterable<String> ids) async {
    final missing = ids.where((id) => !_names.containsKey(id)).toSet().toList();
    if (missing.isEmpty) return;
    final rows = await _db.from('profiles').select('id, name, avatar_url, deleted_at').inFilter('id', missing);
    for (final r in rows) {
      _names[r['id'] as String] = shownName(r['name'] as String, parseTime(r['deleted_at']));
      _avatars[r['id'] as String] = r['avatar_url'] as String?;
    }
  }

  /// Live list of messages in a group, oldest first.
  Stream<List<ChatMessage>> messages(String groupId) {
    return _db
        .from('messages')
        .stream(primaryKey: ['id'])
        .eq('group_id', groupId)
        .order('created_at', ascending: true)
        .asyncMap((rows) async {
      await _resolveNames(rows.map((r) => r['sender_id'] as String));
      return rows
          .map((r) => ChatMessage.fromMap(r, senderName: _names[r['sender_id']] ?? 'Someone'))
          .toList();
    });
  }

  Future<void> send(String groupId, String body) async {
    await _db.from('messages').insert({'group_id': groupId, 'body': body.trim()});
  }

  Future<List<MyGroup>> myGroups() async {
    final uid = _db.auth.currentUser?.id;
    if (uid == null) return [];
    final rows = await _db
        .from('group_members')
        .select('group_id, event_groups(id, number, event_id, group_members(count), events(title, category, ends_at))')
        .eq('user_id', uid);

    final groups = <MyGroup>[];
    for (final r in rows) {
      final g = r['event_groups'] as Map<String, dynamic>;
      final ev = g['events'] as Map<String, dynamic>;
      final countList = g['group_members'] as List;
      final last = await _db
          .from('messages')
          .select('body, created_at')
          .eq('group_id', g['id'])
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();
      groups.add(MyGroup(
        groupId: g['id'] as String,
        groupNumber: (g['number'] as num).toInt(),
        eventId: g['event_id'] as String,
        eventTitle: ev['title'] as String,
        category: ev['category'] as String,
        endsAt: DateTime.parse(ev['ends_at'] as String).toLocal(),
        memberCount: countList.isEmpty ? 0 : (countList.first['count'] as num).toInt(),
        lastMessage: last?['body'] as String?,
        lastAt: last == null ? null : DateTime.parse(last['created_at'] as String).toLocal(),
      ));
    }
    groups.sort((a, b) => (b.lastAt ?? b.endsAt).compareTo(a.lastAt ?? a.endsAt));
    return groups;
  }
}
