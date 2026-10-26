import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/models.dart';
import '../services/auth_service.dart';
import '../services/event_service.dart';
import '../services/chat_service.dart';
import '../services/rating_service.dart';

class AppState extends ChangeNotifier {
  final AuthService auth = AuthService();
  final EventService eventService = EventService();
  final ChatService chat = ChatService();
  final RatingService ratings = RatingService();
  late final StreamSubscription<AuthState> _authSub;

  bool _isDarkMode = true;
  late String _currentScreen;
  String? _selectedEventId;
  String? _selectedGroupId;
  Map<String, dynamic>? _selectedFriend;
  Profile? _me;

  bool _isPickingLocation = false;
  PickedLocation? _pickedLocation;
  List<JoinMeEvent> _events = [];
  /// Unsaved Create Event form, kept while the user picks a location on the map.
  Map<String, dynamic>? createFormCache;
  /// Email typed on the login screen, prefilled on the reset password screen.
  String? resetEmail;
  bool _inPasswordRecovery = false;
  bool get inPasswordRecovery => _inPasswordRecovery;

  void finishPasswordRecovery() {
    _inPasswordRecovery = false;
    resetEmail = null;
    navigateTo('map');
  }
  bool _loadingEvents = false;
  String? _eventsError;
  RealtimeChannel? _eventsChannel;

  AppState() {
    _currentScreen = auth.isSignedIn ? 'map' : 'login';
    if (auth.isSignedIn) loadMe();
    _authSub = auth.changes.listen((state) {
      if (state.event == AuthChangeEvent.signedOut) {
        _me = null;
        _events = [];
        _pickedLocation = null;
        _unsubscribeEvents();
        _currentScreen = 'login';
        notifyListeners();
      } else if (state.event == AuthChangeEvent.passwordRecovery) {
        // Opened from the reset email: the user is signed in and must pick a new password.
        _inPasswordRecovery = true;
        _currentScreen = 'resetPassword';
        notifyListeners();
        loadMe();
      } else if (state.event == AuthChangeEvent.signedIn) {
        loadMe();
      }
    });
  }

  bool get isDarkMode => _isDarkMode;
  String get currentScreen => _currentScreen;
  String? get selectedEventId => _selectedEventId;
  String? get selectedGroupId => _selectedGroupId;
  Map<String, dynamic>? get selectedFriend => _selectedFriend;
  bool get isPickingLocation => _isPickingLocation;
  PickedLocation? get pickedLocation => _pickedLocation;
  Profile? get me => _me;
  List<JoinMeEvent> get events => _events;
  bool get loadingEvents => _loadingEvents;
  String? get eventsError => _eventsError;

  Future<void> refreshEvents() async {
    if (!auth.isSignedIn) return;
    _loadingEvents = true;
    notifyListeners();
    try {
      _events = await eventService.fetchActive();
      _eventsError = null;
    } catch (e) {
      debugPrint('refreshEvents failed: $e');
      _eventsError = 'Could not load events';
    } finally {
      _loadingEvents = false;
      notifyListeners();
    }
    _eventsChannel ??= eventService.subscribeChanges(_onEventsChanged);
  }

  Timer? _refreshDebounce;
  void _onEventsChanged() {
    _refreshDebounce?.cancel();
    _refreshDebounce = Timer(const Duration(milliseconds: 500), refreshEvents);
  }

  void _unsubscribeEvents() {
    _refreshDebounce?.cancel();
    final ch = _eventsChannel;
    _eventsChannel = null;
    if (ch != null) Supabase.instance.client.removeChannel(ch);
  }

  /// Saves the event and returns its id.
  Future<String> createEvent(EventDraft draft) async {
    final id = await eventService.create(draft);
    _pickedLocation = null;
    await refreshEvents();
    return id;
  }

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

  Future<void> updateProfile({required String name, String? bio}) async {
    final uid = auth.userId;
    if (uid == null) return;
    final trimmedBio = bio?.trim();
    await Supabase.instance.client.from('profiles').update({
      'name': name.trim(),
      'bio': (trimmedBio == null || trimmedBio.isEmpty) ? null : trimmedBio,
    }).eq('id', uid);
    await loadMe();
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

  void navigateTo(String screen, {String? eventId, String? groupId, Map<String, dynamic>? friendData}) {
    if (eventId != null) _selectedEventId = eventId;
    if (groupId != null) _selectedGroupId = groupId;
    if (friendData != null) _selectedFriend = friendData;
    _currentScreen = screen;
    notifyListeners();
  }

  @override
  void dispose() {
    _authSub.cancel();
    _unsubscribeEvents();
    super.dispose();
  }
}

class PickedLocation {
  final double lat;
  final double lng;
  final String name;

  PickedLocation({required this.lat, required this.lng, required this.name});
}
