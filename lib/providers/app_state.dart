import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/models.dart';
import '../services/auth_service.dart';

class AppState extends ChangeNotifier {
  final AuthService auth = AuthService();
  late final StreamSubscription<AuthState> _authSub;

  bool _isDarkMode = true;
  late String _currentScreen;
  String? _selectedEventId;
  Map<String, dynamic>? _selectedFriend;
  Profile? _me;

  bool _isPickingLocation = false;
  PickedLocation? _pickedLocation;

  AppState() {
    _currentScreen = auth.isSignedIn ? 'map' : 'login';
    if (auth.isSignedIn) loadMe();
    _authSub = auth.changes.listen((state) {
      if (state.event == AuthChangeEvent.signedOut) {
        _me = null;
        _currentScreen = 'login';
        notifyListeners();
      } else if (state.event == AuthChangeEvent.signedIn) {
        loadMe();
      }
    });
  }

  bool get isDarkMode => _isDarkMode;
  String get currentScreen => _currentScreen;
  String? get selectedEventId => _selectedEventId;
  Map<String, dynamic>? get selectedFriend => _selectedFriend;
  bool get isPickingLocation => _isPickingLocation;
  PickedLocation? get pickedLocation => _pickedLocation;
  Profile? get me => _me;

  Future<void> loadMe() async {
    final uid = auth.userId;
    if (uid == null) return;
    try {
      final row = await Supabase.instance.client
          .from('profile_stats')
          .select()
          .eq('id', uid)
          .maybeSingle();
      if (row != null) {
        _me = Profile.fromStats(row);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('loadMe failed: $e');
    }
  }

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

  @override
  void dispose() {
    _authSub.cancel();
    super.dispose();
  }
}

class PickedLocation {
  final double lat;
  final double lng;
  final String name;

  PickedLocation({required this.lat, required this.lng, required this.name});
}
