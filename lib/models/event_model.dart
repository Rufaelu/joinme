import 'package:cloud_firestore/cloud_firestore.dart';

class EventHost {
  final String name;
  final String avatar;
  final int reliability;

  EventHost({
    required this.name,
    required this.avatar,
    required this.reliability,
  });

  factory EventHost.fromJson(Map<String, dynamic> json) {
    return EventHost(
      name: json['name'] as String? ?? 'Anonymous',
      avatar: json['avatar'] as String? ?? 'AN',
      reliability: json['reliability'] as int? ?? 100,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'avatar': avatar,
      'reliability': reliability,
    };
  }
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

  factory EventLocation.fromJson(Map<String, dynamic> json) {
    return EventLocation(
      lat: (json['lat'] as num?)?.toDouble() ?? 0.0,
      lng: (json['lng'] as num?)?.toDouble() ?? 0.0,
      name: json['name'] as String? ?? 'Unknown Location',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'lat': lat,
      'lng': lng,
      'name': name,
    };
  }
}

class JoinMeEvent {
  final String id;
  final String title;
  final String category;
  final String organizerId;
  final EventHost host;
  final EventLocation location;
  final int participants;
  final int maxParticipants;
  final int timeRemaining;
  final int duration;
  final String? description;
  final List<String> participantAvatars;
  final String? imageUrl;
  final DateTime createdAt;
  final DateTime updatedAt;

  JoinMeEvent({
    required this.id,
    required this.title,
    required this.category,
    this.organizerId = '',
    required this.host,
    required this.location,
    required this.participants,
    required this.maxParticipants,
    required this.timeRemaining,
    required this.duration,
    this.description,
    required this.participantAvatars,
    this.imageUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  JoinMeEvent copyWith({
    String? id,
    String? title,
    String? category,
    String? organizerId,
    EventHost? host,
    EventLocation? location,
    int? participants,
    int? maxParticipants,
    int? timeRemaining,
    int? duration,
    String? description,
    List<String>? participantAvatars,
    String? imageUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return JoinMeEvent(
      id: id ?? this.id,
      title: title ?? this.title,
      category: category ?? this.category,
      organizerId: organizerId ?? this.organizerId,
      host: host ?? this.host,
      location: location ?? this.location,
      participants: participants ?? this.participants,
      maxParticipants: maxParticipants ?? this.maxParticipants,
      timeRemaining: timeRemaining ?? this.timeRemaining,
      duration: duration ?? this.duration,
      description: description ?? this.description,
      participantAvatars: participantAvatars ?? this.participantAvatars,
      imageUrl: imageUrl ?? this.imageUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory JoinMeEvent.fromJson(Map<String, dynamic> json, String documentId) {
    return JoinMeEvent(
      id: documentId,
      title: json['title'] as String? ?? '',
      category: json['category'] as String? ?? 'sports',
      organizerId: json['organizerId'] as String? ?? '',
      host: EventHost.fromJson(json['host'] as Map<String, dynamic>? ?? {}),
      location: EventLocation.fromJson(json['location'] as Map<String, dynamic>? ?? {}),
      participants: json['participants'] as int? ?? 1,
      maxParticipants: json['maxParticipants'] as int? ?? 10,
      timeRemaining: json['timeRemaining'] as int? ?? 60,
      duration: json['duration'] as int? ?? 60,
      description: json['description'] as String?,
      participantAvatars: List<String>.from(json['participantAvatars'] ?? []),
      imageUrl: json['imageUrl'] as String?,
      createdAt: json['createdAt'] != null
          ? (json['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? (json['updatedAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'category': category,
      'organizerId': organizerId,
      'host': host.toJson(),
      'location': location.toJson(),
      'participants': participants,
      'maxParticipants': maxParticipants,
      'timeRemaining': timeRemaining,
      'duration': duration,
      'description': description,
      'participantAvatars': participantAvatars,
      'imageUrl': imageUrl,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }
}
