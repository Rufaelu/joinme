import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/models.dart';
import '../services/auth_service.dart';
import '../services/event_service.dart';
import '../services/chat_service.dart';
import '../services/rating_service.dart';
import '../services/storage_service.dart';
import '../services/social_service.dart';
import '../models/social.dart';
import 'nav_history.dart';

class AppState extends ChangeNotifier {
  final AuthService auth = AuthService();
  final EventService eventService = EventService();
  final ChatService chat = ChatService();
  final RatingService ratings = RatingService();
  final StorageService storage = StorageService();
  final SocialService social = SocialService();
  StreamSubscription<List<AppNotification>>? _notifSub;
  List<AppNotification> _notifications = [];
  List<AppNotification> get notifications => _notifications;
  int get unreadCount => _notifications.where((n) => !n.read).length;
  /// Tab the Friends screen opens on ('friends', 'requests' or 'find').
  String friendsTab = 'friends';

  /// Live notifications for the bell badge and Notifications screen.
  void _watchNotifications() {
    _notifSub?.cancel();
    if (!auth.isSignedIn) return;
    _notifSub = social.notifications().listen(
      (list) {
        _notifications = list;
        notifyListeners();
      },
      onError: (e) => debugPrint('notifications stream failed: $e'),
    );
  }

  void _stopNotifications() {
    _notifSub?.cancel();
    _notifSub = null;
    _notifications = [];
  }
  late final StreamSubscription<AuthState> _authSub;
  final NavHistory _history = NavHistory();

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
    if (auth.isSignedIn) {
      loadMe();
      _watchNotifications();
    }
    _authSub = auth.changes.listen((state) {
      if (state.event == AuthChangeEvent.signedOut) {
        _me = null;
        _events = [];
        _pickedLocation = null;
        _unsubscribeEvents();
        _stopNotifications();
        _selectedFriend = null;
        createFormCache = null;
        _history.clear();
        _currentScreen = 'login';
        notifyListeners();
      } else if (state.event == AuthChangeEvent.passwordRecovery) {
        // Opened from the reset email: the user is signed in and must pick a new password.
        _inPasswordRecovery = true;
        _history.clear();
        _currentScreen = 'resetPassword';
        notifyListeners();
        loadMe();
      } else if (state.event == AuthChangeEvent.signedIn) {
        loadMe();
        _watchNotifications();
        // Google sign-in returns here from the browser while the login screen is showing.
        if (_currentScreen == 'login') {
          _history.clear();
          _currentScreen = 'map';
          notifyListeners();
        }
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
        // A deleted account that signs in again is offered a restore first.
        if (_me!.isDeleted && _currentScreen != 'restoreAccount') {
          _history.clear();
          _currentScreen = 'restoreAccount';
        }
        notifyListeners();
      }
    } catch (e) {
      debugPrint('loadMe failed: $e');
    }
  }

  Future<void> updateProfile({required String name, String? bio, String? avatarUrl}) async {
    final uid = auth.userId;
    if (uid == null) return;
    final trimmedBio = bio?.trim();
    await Supabase.instance.client.from('profiles').update({
      'name': name.trim(),
      'bio': (trimmedBio == null || trimmedBio.isEmpty) ? null : trimmedBio,
      if (avatarUrl != null) 'avatar_url': avatarUrl,
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

  /// Shows [screen]. With [replace], back skips the current screen.
  void navigateTo(String screen,
      {String? eventId, String? groupId, Map<String, dynamic>? friendData, bool replace = false}) {
    _history.push(
      NavEntry(_currentScreen, eventId: _selectedEventId, groupId: _selectedGroupId, friendData: _selectedFriend),
      next: screen,
      replace: replace,
    );
    if (eventId != null) _selectedEventId = eventId;
    if (groupId != null) _selectedGroupId = groupId;
    if (friendData != null) _selectedFriend = friendData;
    _currentScreen = screen;
    notifyListeners();
  }

  /// Android back button. Returns false when the app should close.
  bool goBack() {
    if (_currentScreen == 'create') {
      createFormCache = null;
      _isPickingLocation = false;
    }
    // Picking a location for a new event: back returns to the form.
    if (_currentScreen == 'map' && _isPickingLocation) {
      _isPickingLocation = false;
      _currentScreen = 'create';
      notifyListeners();
      return true;
    }
    if (_inPasswordRecovery || _currentScreen == 'login' || _currentScreen == 'restoreAccount') return false;

    final prev = _history.pop();
    if (prev == null) {
      if (_currentScreen == 'map' || _currentScreen == 'onboarding') return false;
      _currentScreen = auth.isSignedIn ? 'map' : 'login';
      notifyListeners();
      return true;
    }
    _currentScreen = prev.screen;
    if (prev.eventId != null) _selectedEventId = prev.eventId;
    if (prev.groupId != null) _selectedGroupId = prev.groupId;
    if (prev.friendData != null) _selectedFriend = prev.friendData;
    notifyListeners();
    return true;
  }

  @override
  void dispose() {
    _authSub.cancel();
    _unsubscribeEvents();
    _notifSub?.cancel();
    super.dispose();
  }
}

class PickedLocation {
  final double lat;
  final double lng;
  final String name;

  PickedLocation({required this.lat, required this.lng, required this.name});
}
