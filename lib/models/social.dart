// Friends, direct messages, notifications and map place search.
import 'models.dart' show shownName, parseTime;

/// Key shared by both directions of a direct-message chat. Must match the
/// `pair_key` column in supabase/schema.sql (smaller uuid first).
String pairKey(String a, String b) => a.compareTo(b) <= 0 ? '$a:$b' : '$b:$a';

enum FriendRelation { none, friends, incoming, outgoing }

FriendRelation relationFor({
  required String requesterId,
  required String addresseeId,
  required String status,
  required String me,
}) {
  if (status == 'accepted') return FriendRelation.friends;
  return requesterId == me ? FriendRelation.outgoing : FriendRelation.incoming;
}

/// Another person as shown in friend lists and search results.
class Person {
  final String id;
  final String name;
  final String? avatarUrl;
  final double? reputation;
  final int ratingCount;
  final FriendRelation relation;
  final DateTime? deletedAt;

  Person({
    required this.id,
    required this.name,
    this.avatarUrl,
    this.reputation,
    this.ratingCount = 0,
    this.relation = FriendRelation.none,
    this.deletedAt,
  });

  bool get isDeleted => deletedAt != null;
  String get displayName => shownName(name, deletedAt);

  Person withRelation(FriendRelation r) => Person(
        id: id,
        name: name,
        avatarUrl: avatarUrl,
        reputation: reputation,
        ratingCount: ratingCount,
        relation: r,
        deletedAt: deletedAt,
      );

  factory Person.fromStats(Map<String, dynamic> row, {FriendRelation relation = FriendRelation.none}) {
    final rep = row['reputation'];
    return Person(
      id: row['id'] as String,
      name: row['name'] as String,
      avatarUrl: row['avatar_url'] as String?,
      reputation: rep == null ? null : (rep as num).toDouble(),
      ratingCount: (row['rating_count'] as num?)?.toInt() ?? 0,
      relation: relation,
      deletedAt: parseTime(row['deleted_at']),
    );
  }
}

class DirectMessage {
  final int id;
  final String senderId;
  final String recipientId;
  final String body;
  final DateTime createdAt;

  DirectMessage({
    required this.id,
    required this.senderId,
    required this.recipientId,
    required this.body,
    required this.createdAt,
  });

  factory DirectMessage.fromMap(Map<String, dynamic> row) => DirectMessage(
        id: (row['id'] as num).toInt(),
        senderId: row['sender_id'] as String,
        recipientId: row['recipient_id'] as String,
        body: row['body'] as String,
        createdAt: DateTime.parse(row['created_at'] as String).toLocal(),
      );
}

/// Latest message with one friend, for the Messages list.
class DmThread {
  final Person friend;
  final String? lastMessage;
  final DateTime? lastAt;

  DmThread({required this.friend, this.lastMessage, this.lastAt});
}

class AppNotification {
  final int id;
  final String type;
  final String? actorId;
  final String? eventId;
  final String body;
  final bool read;
  final DateTime createdAt;

  AppNotification({
    required this.id,
    required this.type,
    this.actorId,
    this.eventId,
    required this.body,
    required this.read,
    required this.createdAt,
  });

  factory AppNotification.fromMap(Map<String, dynamic> row) => AppNotification(
        id: (row['id'] as num).toInt(),
        type: row['type'] as String,
        actorId: row['actor_id'] as String?,
        eventId: row['event_id'] as String?,
        body: row['body'] as String,
        read: row['read'] as bool? ?? false,
        createdAt: DateTime.parse(row['created_at'] as String).toLocal(),
      );
}

/// Which screen tapping a notification of [type] opens.
String notificationScreen(String type) {
  switch (type) {
    case 'friend_request':
      return 'friends';
    case 'friend_accepted':
    case 'direct_message':
      return 'directChat';
    case 'event_joined':
      return 'event';
    default:
      return 'notifications';
  }
}

/// A place found by the map search (OpenStreetMap Nominatim).
class PlaceResult {
  final String name;
  final String subtitle;
  final double lat;
  final double lng;

  PlaceResult({required this.name, required this.subtitle, required this.lat, required this.lng});

  factory PlaceResult.fromNominatim(Map<String, dynamic> row) {
    final parts = (row['display_name'] as String? ?? '').split(', ');
    final rawName = (row['name'] as String? ?? '').trim();
    final name = rawName.isNotEmpty ? rawName : parts.first;
    final rest = parts.first == name ? parts.skip(1) : parts;
    return PlaceResult(
      name: name,
      subtitle: rest.take(3).join(', '),
      lat: double.parse(row['lat'] as String),
      lng: double.parse(row['lon'] as String),
    );
  }
}
