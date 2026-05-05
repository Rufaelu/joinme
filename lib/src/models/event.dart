import 'package:latlong2/latlong.dart';

enum EventCategory { sports, study, social, food }

extension EventCategoryInfo on EventCategory {
  String get label {
    switch (this) {
      case EventCategory.sports:
        return 'Sports';
      case EventCategory.study:
        return 'Study';
      case EventCategory.social:
        return 'Social';
      case EventCategory.food:
        return 'Food';
    }
  }

  String get icon {
    switch (this) {
      case EventCategory.sports:
        return '⚽';
      case EventCategory.study:
        return '📚';
      case EventCategory.social:
        return '🎉';
      case EventCategory.food:
        return '☕';
    }
  }

  int get colorValue {
    switch (this) {
      case EventCategory.sports:
        return 0xFF3B82F6;
      case EventCategory.study:
        return 0xFF7C3AED;
      case EventCategory.social:
        return 0xFF16A34A;
      case EventCategory.food:
        return 0xFFF97316;
    }
  }
}

class EventModel {
  EventModel({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.dateTime,
    required this.location,
    required this.locationName,
    required this.hostId,
    required this.maxParticipants,
    List<String>? participantIds,
    required this.rating,
    required this.duration,
  }) : participantIds = participantIds ?? [];

  final String id;
  final String title;
  final String description;
  final EventCategory category;
  final DateTime dateTime;
  final LatLng location;
  final String locationName;
  final String hostId;
  final int maxParticipants;
  final double rating;
  final String duration;
  final List<String> participantIds;

  bool get isFull => participantIds.length >= maxParticipants;
  int get participantsCount => participantIds.length;
  double get loadFactor => maxParticipants == 0 ? 0 : participantsCount / maxParticipants;
}
