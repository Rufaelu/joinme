export '../models/models.dart';

// Friends and direct messages are still mock data.
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

final List<Friend> mockFriends = [
  Friend(id: '1', name: 'Dawit Tadesse', avatar: 'DT', reliability: 92, mutualEvents: 5, status: 'accepted'),
  Friend(id: '2', name: 'Selamawit Kebede', avatar: 'SK', reliability: 88, mutualEvents: 3, status: 'accepted'),
  Friend(id: '3', name: 'Mahlet Alemu', avatar: 'MA', reliability: 95, mutualEvents: 7, status: 'accepted'),
  Friend(id: '4', name: 'Abebe Bikila', avatar: 'AB', reliability: 94, mutualEvents: 2, status: 'received'),
  Friend(id: '5', name: 'Yohannes Getachew', avatar: 'YG', reliability: 90, mutualEvents: 4, status: 'pending'),
];
