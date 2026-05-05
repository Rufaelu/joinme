import 'package:flutter/foundation.dart';
import 'package:joinme/src/models/chat.dart';
import 'package:joinme/src/models/event.dart';
import 'package:joinme/src/models/user.dart';
import 'package:joinme/src/services/mock_data.dart' as mock_data;
import 'package:latlong2/latlong.dart';

class AppState extends ChangeNotifier {
  AppState() {
    _events = mock_data.events.map((event) => event).toList();
    _chatThreads = mock_data.chatThreads.map((thread) => thread).toList();
    _users = mock_data.users.map((user) => user).toList();
    currentUser = _users.firstWhere((user) => user.id == mock_data.currentUser.id, orElse: () => _users.first);
  }

  late final UserModel currentUser;
  late final List<UserModel> _users;
  late final List<EventModel> _events;
  late final List<ChatThread> _chatThreads;
  String searchQuery = '';
  EventCategory? selectedCategory;
  LatLng? selectedLocation;

  List<EventModel> get events {
    var filtered = _events;
    if (selectedCategory != null) {
      filtered = filtered.where((event) => event.category == selectedCategory).toList();
    }
    if (searchQuery.isNotEmpty) {
      filtered = filtered.where((event) {
        final query = searchQuery.toLowerCase();
        return event.title.toLowerCase().contains(query) ||
            event.description.toLowerCase().contains(query) ||
            event.locationName.toLowerCase().contains(query);
      }).toList();
    }
    return filtered;
  }

  List<ChatThread> get chatThreads => _chatThreads;

  List<UserModel> get friends => _users.where((user) => user.id != currentUser.id).toList();
  List<UserModel> get onlineFriends => friends.where((user) => user.online).toList();
  List<UserModel> get friendSuggestions => friends.take(3).toList();

  void setSearchQuery(String query) {
    searchQuery = query;
    notifyListeners();
  }

  void setFilterCategory(EventCategory? category) {
    selectedCategory = category;
    notifyListeners();
  }

  void pickLocation(LatLng location) {
    selectedLocation = location;
    notifyListeners();
  }

  void createEvent(EventModel event) {
    _events.insert(0, event);
    notifyListeners();
  }

  void joinEvent(String eventId) {
    final event = _events.firstWhere((element) => element.id == eventId);
    if (!event.participantIds.contains(currentUser.id) && !event.isFull) {
      event.participantIds.add(currentUser.id);
      notifyListeners();
    }
  }

  void leaveEvent(String eventId) {
    final event = _events.firstWhere((element) => element.id == eventId);
    event.participantIds.remove(currentUser.id);
    notifyListeners();
  }

  void updateProfile({required String name, required String bio, required List<String> interests}) {
    currentUser.name = name;
    currentUser.bio = bio;
    currentUser.interests = interests;
    notifyListeners();
  }

  void acceptFriend(String userId) {
    final user = _users.firstWhere((user) => user.id == userId, orElse: () => _users.first);
    if (user.id != currentUser.id) {
      currentUser.friendsCount += 1;
      notifyListeners();
    }
  }

  ChatThread? getChatThreadForEvent(String eventId) {
    try {
      return _chatThreads.firstWhere((thread) => thread.relatedEventId == eventId);
    } catch (_) {
      return null;
    }
  }
}

final appState = AppState();
