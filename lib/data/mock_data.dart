import 'package:flutter/material.dart';

class EventCategory {
  static const String sports = 'sports';
  static const String study = 'study';
  static const String chill = 'chill';
  static const String creative = 'creative';
}

class EventHost {
  final String name;
  final String avatar;
  final int reliability;

  EventHost({
    required this.name,
    required this.avatar,
    required this.reliability,
  });
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
  final EventHost host;
  final EventLocation location;
  final int participants;
  final int maxParticipants;
  final int timeRemaining;
  final int duration;
  final String? description;
  final List<String> participantAvatars;

  JoinMeEvent({
    required this.id,
    required this.title,
    required this.category,
    required this.host,
    required this.location,
    required this.participants,
    required this.maxParticipants,
    required this.timeRemaining,
    required this.duration,
    this.description,
    required this.participantAvatars,
  });
}

class Friend {
  final String id;
  final String name;
  final String avatar;
  final int reliability;
  final int mutualEvents;
  final String status;

  Friend({
    required this.id,
    required this.name,
    required this.avatar,
    required this.reliability,
    required this.mutualEvents,
    required this.status,
  });
}

final currentUser = {
  'name': 'You',
  'avatar': 'YU',
  'reliability': 87,
  'eventsAttended': 34,
  'eventsHosted': 12,
  'pastEvents': [
    {'title': 'Morning Yoga', 'category': 'sports', 'date': '2026-02-20'},
    {'title': 'Book Club', 'category': 'study', 'date': '2026-02-19'},
    {'title': 'Brunch Meetup', 'category': 'chill', 'date': '2026-02-18'},
    {'title': 'Photography Walk', 'category': 'creative', 'date': '2026-02-17'},
    {'title': 'Tennis Match', 'category': 'sports', 'date': '2026-02-16'},
    {'title': 'Language Exchange', 'category': 'study', 'date': '2026-02-15'}
  ]
};

final List<Friend> mockFriends = [
  Friend(id: '1', name: 'Dawit Tadesse', avatar: 'DT', reliability: 92, mutualEvents: 5, status: 'accepted'),
  Friend(id: '2', name: 'Selamawit Kebede', avatar: 'SK', reliability: 88, mutualEvents: 3, status: 'accepted'),
  Friend(id: '3', name: 'Mahlet Alemu', avatar: 'MA', reliability: 95, mutualEvents: 7, status: 'accepted'),
  Friend(id: '4', name: 'Abebe Bikila', avatar: 'AB', reliability: 94, mutualEvents: 2, status: 'received'),
  Friend(id: '5', name: 'Yohannes Getachew', avatar: 'YG', reliability: 90, mutualEvents: 4, status: 'pending'),
];

final List<JoinMeEvent> mockEvents = [
  JoinMeEvent(
    id: '1',
    title: 'Pickup Football Match',
    category: 'sports',
    host: EventHost(name: 'Dawit Tadesse', avatar: 'DT', reliability: 92),
    location: EventLocation(lat: 9.0100, lng: 38.7610, name: 'Meskel Square'),
    participants: 8,
    maxParticipants: 12,
    timeRemaining: 45,
    duration: 120,
    description: 'Friendly 6v6 football match. All skill levels welcome!',
    participantAvatars: ['DT', 'MK', 'TL', 'SB', 'JD', 'RP', 'KM', 'LW'],
  ),
  JoinMeEvent(
    id: '2',
    title: 'Study Session - Web Dev',
    category: 'study',
    host: EventHost(name: 'Selamawit Kebede', avatar: 'SK', reliability: 88),
    location: EventLocation(lat: 9.0350, lng: 38.7520, name: 'Tomoca Coffee, Piassa'),
    participants: 4,
    maxParticipants: 6,
    timeRemaining: 20,
    duration: 90,
    description: 'Working on React projects together. Bring your laptop!',
    participantAvatars: ['SK', 'BN', 'JM', 'TP'],
  ),
  JoinMeEvent(
    id: '3',
    title: 'Coffee & Vibes',
    category: 'chill',
    host: EventHost(name: 'Mikiyas Torres', avatar: 'MT', reliability: 75),
    location: EventLocation(lat: 8.9950, lng: 38.7890, name: 'Bole Medhane Alem'),
    participants: 3,
    maxParticipants: 5,
    timeRemaining: 15,
    duration: 60,
    description: 'Just hanging out and chatting over coffee',
    participantAvatars: ['MT', 'HL', 'DN'],
  ),
  JoinMeEvent(
    id: '4',
    title: 'Sketch Jam',
    category: 'creative',
    host: EventHost(name: 'Mahlet Alemu', avatar: 'MA', reliability: 95),
    location: EventLocation(lat: 9.0400, lng: 38.7600, name: 'National Museum'),
    participants: 5,
    maxParticipants: 8,
    timeRemaining: 60,
    duration: 120,
    description: 'Open sketching session. Bring materials or use ours!',
    participantAvatars: ['MA', 'KR', 'NS', 'VB', 'PL'],
  ),
  JoinMeEvent(
    id: '5',
    title: 'Basketball Hoops',
    category: 'sports',
    host: EventHost(name: 'Jordan Lee', avatar: 'JL', reliability: 82),
    location: EventLocation(lat: 9.0250, lng: 38.7450, name: 'Lideta Courts'),
    participants: 6,
    maxParticipants: 10,
    timeRemaining: 30,
    duration: 90,
    description: '3v3 pickup games happening now!',
    participantAvatars: ['JL', 'CM', 'RW', 'TB', 'NK', 'FM'],
  ),
  JoinMeEvent(
    id: '6',
    title: 'Board Game Night',
    category: 'chill',
    host: EventHost(name: 'Liyu Park', avatar: 'LP', reliability: 90),
    location: EventLocation(lat: 9.0150, lng: 38.7750, name: 'Kazanchis Game Cafe'),
    participants: 4,
    maxParticipants: 6,
    timeRemaining: 25,
    duration: 150,
    description: 'Playing Catan and other strategy games',
    participantAvatars: ['LP', 'GH', 'MW', 'SL'],
  ),
  JoinMeEvent(
    id: '7',
    title: 'Morning Run Club',
    category: 'sports',
    host: EventHost(name: 'Abebe Bikila', avatar: 'AB', reliability: 94),
    location: EventLocation(lat: 9.0500, lng: 38.7500, name: 'Entoto Park'),
    participants: 7,
    maxParticipants: 15,
    timeRemaining: 55,
    duration: 60,
    description: '5K run around the park. All paces welcome!',
    participantAvatars: ['AB', 'AS', 'KL', 'WB', 'PK', 'MN', 'TY'],
  ),
  JoinMeEvent(
    id: '8',
    title: 'Amharic Language Exchange',
    category: 'study',
    host: EventHost(name: 'Carlos Rodriguez', avatar: 'CR', reliability: 86),
    location: EventLocation(lat: 9.0050, lng: 38.7800, name: 'Edna Mall Area'),
    participants: 5,
    maxParticipants: 8,
    timeRemaining: 40,
    duration: 90,
    description: 'Practice Amharic with native speakers',
    participantAvatars: ['CR', 'LM', 'JT', 'SR', 'NK'],
  ),
];
