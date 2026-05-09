import 'package:flutter/material.dart';
import '../data/mock_data.dart';

class AppState extends ChangeNotifier {
  bool _isDarkMode = true;
  String _currentScreen = 'login';
  String? _selectedEventId;
  Map<String, dynamic>? _selectedFriend;
  
  bool _isPickingLocation = false;
  PickedLocation? _pickedLocation;
  List<JoinMeEvent> _events = List.from(mockEvents);

  bool get isDarkMode => _isDarkMode;
  String get currentScreen => _currentScreen;
  String? get selectedEventId => _selectedEventId;
  Map<String, dynamic>? get selectedFriend => _selectedFriend;
  bool get isPickingLocation => _isPickingLocation;
  PickedLocation? get pickedLocation => _pickedLocation;
  List<JoinMeEvent> get events => _events;

  void toggleTheme() {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
  }

  void setPickingLocation(bool value) {
    _isPickingLocation = value;
    notifyListeners();
  }

  void setPickedLocation(PickedLocation location) {
    _pickedLocation = location;
    _isPickingLocation = false;
    notifyListeners();
  }

  void navigateTo(String screen, {String? eventId, Map<String, dynamic>? friendData}) {
    if (eventId != null) _selectedEventId = eventId;
    if (friendData != null) _selectedFriend = friendData;
    _currentScreen = screen;
    notifyListeners();
  }

  void addEvent(JoinMeEvent event) {
    _events.add(event);
    notifyListeners();
  }
}

class PickedLocation {
  final double lat;
  final double lng;
  final String name;

  PickedLocation({required this.lat, required this.lng, required this.name});
}
