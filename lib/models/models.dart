class EventCategory {
  static const String sports = 'sports';
  static const String study = 'study';
  static const String chill = 'chill';
  static const String creative = 'creative';
}

String initialsOf(String name) {
  final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
  if (parts.isEmpty) return '?';
  return parts.take(2).map((p) => p[0].toUpperCase()).join();
}

String formatReputation(double? rep) => rep == null ? 'New' : rep.toStringAsFixed(1);

double? _toDouble(dynamic v) => v == null ? null : (v as num).toDouble();

class EventHost {
  final String id;
  final String name;
  final double? reputation;
  final int ratingCount;

  EventHost({
    required this.id,
    required this.name,
    this.reputation,
    this.ratingCount = 0,
  });

  String get avatar => initialsOf(name);
}

class EventLocation {
  final double lat;
  final double lng;
  final String name;

  EventLocation({
    required this.lat,
    required this.lng,
    required this.name,
  });
}

class JoinMeEvent {
  final String id;
  final String title;
  final String category;
  final String? description;
  final EventHost host;
  final EventLocation location;
  final DateTime startsAt;
  final DateTime endsAt;
  final int groupSize;
  final int memberCount;
  final int groupCount;

  JoinMeEvent({
    required this.id,
    required this.title,
    required this.category,
    this.description,
    required this.host,
    required this.location,
    required this.startsAt,
    required this.endsAt,
    required this.groupSize,
    required this.memberCount,
    required this.groupCount,
  });

  factory JoinMeEvent.fromFeed(Map<String, dynamic> row) {
    return JoinMeEvent(
      id: row['id'] as String,
      title: row['title'] as String,
      category: row['category'] as String,
      description: row['description'] as String?,
      host: EventHost(
        id: row['host_id'] as String,
        name: row['host_name'] as String,
        reputation: _toDouble(row['host_reputation']),
        ratingCount: (row['host_rating_count'] as num?)?.toInt() ?? 0,
      ),
      location: EventLocation(
        lat: (row['lat'] as num).toDouble(),
        lng: (row['lng'] as num).toDouble(),
        name: row['location_name'] as String,
      ),
      startsAt: DateTime.parse(row['starts_at'] as String).toLocal(),
      endsAt: DateTime.parse(row['ends_at'] as String).toLocal(),
      groupSize: (row['group_size'] as num).toInt(),
      memberCount: (row['member_count'] as num?)?.toInt() ?? 0,
      groupCount: (row['group_count'] as num?)?.toInt() ?? 1,
    );
  }

  /// Minutes until the event starts (0 once it has started).
  int get timeRemaining {
    final mins = startsAt.difference(DateTime.now()).inSeconds / 60;
    return mins <= 0 ? 0 : mins.ceil();
  }

  int get duration => endsAt.difference(startsAt).inMinutes;
  bool get hasStarted => !DateTime.now().isBefore(startsAt);
  bool get hasEnded => !DateTime.now().isBefore(endsAt);
  int get participants => memberCount;
  int get maxParticipants => groupSize * groupCount;
}

class Profile {
  final String id;
  final String name;
  final String? bio;
  final double? reputation;
  final int ratingCount;
  final int eventsHosted;
  final int eventsAttended;

  Profile({
    required this.id,
    required this.name,
    this.bio,
    this.reputation,
    this.ratingCount = 0,
    this.eventsHosted = 0,
    this.eventsAttended = 0,
  });

  factory Profile.fromStats(Map<String, dynamic> row) {
    return Profile(
      id: row['id'] as String,
      name: row['name'] as String,
      bio: row['bio'] as String?,
      reputation: _toDouble(row['reputation']),
      ratingCount: (row['rating_count'] as num?)?.toInt() ?? 0,
      eventsHosted: (row['events_hosted'] as num?)?.toInt() ?? 0,
      eventsAttended: (row['events_attended'] as num?)?.toInt() ?? 0,
    );
  }

  String get initials => initialsOf(name);
}

class GroupMember {
  final String id;
  final String name;

  GroupMember({required this.id, required this.name});

  String get initials => initialsOf(name);
}

class EventGroup {
  final String id;
  final String eventId;
  final int number;
  final List<GroupMember> members;

  EventGroup({
    required this.id,
    required this.eventId,
    required this.number,
    required this.members,
  });
}

class ChatMessage {
  final int id;
  final String groupId;
  final String senderId;
  final String senderName;
  final String body;
  final DateTime createdAt;

  ChatMessage({
    required this.id,
    required this.groupId,
    required this.senderId,
    required this.senderName,
    required this.body,
    required this.createdAt,
  });

  factory ChatMessage.fromMap(Map<String, dynamic> row, {required String senderName}) {
    return ChatMessage(
      id: (row['id'] as num).toInt(),
      groupId: row['group_id'] as String,
      senderId: row['sender_id'] as String,
      senderName: senderName,
      body: row['body'] as String,
      createdAt: DateTime.parse(row['created_at'] as String).toLocal(),
    );
  }
}
