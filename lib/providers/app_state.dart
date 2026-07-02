import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' show User;
import 'package:cloud_firestore/cloud_firestore.dart' show FirebaseFirestore;
import '../models/user_model.dart';
import '../models/event_model.dart';
import '../models/notification_model.dart';
import '../repositories/auth_repository.dart';
import '../repositories/user_repository.dart';
import '../repositories/event_repository.dart';
import '../repositories/storage_repository.dart';
import '../repositories/notification_repository.dart';

class AppState extends ChangeNotifier {
  // Repositories
  final AuthRepository _authRepo = AuthRepository();
  final UserRepository _userRepo = UserRepository();
  final EventRepository _eventRepo = EventRepository();
  final StorageRepository _storageRepo = StorageRepository();
  final NotificationRepository _notificationRepo = NotificationRepository();

  // App Theme & Navigation States
  bool _isDarkMode = true;
  String _currentScreen = 'login';
  String? _selectedEventId;
  Map<String, dynamic>? _selectedFriend;
  bool _isPickingLocation = false;
  PickedLocation? _pickedLocation;

  // Real-time Data
  List<JoinMeEvent> _events = [];
  UserModel? _currentUser;
  List<NotificationModel> _notifications = [];
  List<String> _favoriteEventIds = [];

  // Stream Subscriptions
  StreamSubscription<User?>? _authSubscription;
  StreamSubscription<UserModel?>? _userSubscription;
  StreamSubscription<List<JoinMeEvent>>? _eventsSubscription;
  StreamSubscription<List<NotificationModel>>? _notificationsSubscription;
  StreamSubscription<List<String>>? _favoritesSubscription;

  // Getters
  bool get isDarkMode => _isDarkMode;
  String get currentScreen => _currentScreen;
  String? get selectedEventId => _selectedEventId;
  Map<String, dynamic>? get selectedFriend => _selectedFriend;
  bool get isPickingLocation => _isPickingLocation;
  PickedLocation? get pickedLocation => _pickedLocation;

  List<JoinMeEvent> get events => _events;
  UserModel? get currentUser => _currentUser;
  List<NotificationModel> get notifications => _notifications;
  List<String> get favoriteEventIds => _favoriteEventIds;
  bool get isAuthenticated => _currentUser != null;

  AppState() {
    // Listen to authentication changes
    _authSubscription = _authRepo.authStateChanges.listen((User? firebaseUser) {
      if (firebaseUser == null) {
        _cleanupUserStreams();
        _currentUser = null;
        _currentScreen = 'login';
        notifyListeners();
      } else {
        _setupUserStreams(firebaseUser.uid);
      }
    });
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    _cleanupUserStreams();
    super.dispose();
  }

  // --- Auth Setup Streams ---
  void _setupUserStreams(String uid) {
    _cleanupUserStreams();

    // Stream profile details
    _userSubscription = _userRepo.streamUser(uid).listen((UserModel? user) async {
      if (user == null) {
        // Create user document if it does not exist (e.g. Google sign in for first time)
        final firebaseUser = _authRepo.currentUser;
        if (firebaseUser != null) {
          final newUser = UserModel(
            uid: uid,
            fullName: firebaseUser.displayName ?? 'New User',
            email: firebaseUser.email ?? '',
            photoUrl: firebaseUser.photoURL,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );
          await _userRepo.createUser(newUser);
        }
      } else {
        _currentUser = user;
        // Only navigate to map if user was on login/onboarding screen
        if (_currentScreen == 'login' || _currentScreen == 'onboarding') {
          _currentScreen = 'map';
        }
        notifyListeners();
      }
    });

    // Stream Events
    _eventsSubscription = _eventRepo.streamEvents().listen((List<JoinMeEvent> eventList) {
      _events = eventList;
      notifyListeners();
    });

    // Stream Notifications
    _notificationsSubscription = _notificationRepo.streamNotifications(uid).listen((List<NotificationModel> noteList) {
      _notifications = noteList;
      notifyListeners();
    });

    // Stream Favorites
    _favoritesSubscription = _eventRepo.streamFavorites(uid).listen((List<String> favIds) {
      _favoriteEventIds = favIds;
      notifyListeners();
    });
  }

  void _cleanupUserStreams() {
    _userSubscription?.cancel();
    _eventsSubscription?.cancel();
    _notificationsSubscription?.cancel();
    _favoritesSubscription?.cancel();
  }

  // --- Theme ---
  void toggleTheme() {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
  }

  // --- Navigation ---
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

  // --- Auth Actions ---
  Future<void> signUp(String email, String password, String fullName) async {
    try {
      final credential = await _authRepo.signUpWithEmailAndPassword(email, password);
      final newUser = UserModel(
        uid: credential.user!.uid,
        fullName: fullName,
        email: email,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await _userRepo.createUser(newUser);
      _currentScreen = 'map';
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> logIn(String email, String password) async {
    try {
      await _authRepo.logInWithEmailAndPassword(email, password);
      _currentScreen = 'map';
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> signInWithGoogle() async {
    try {
      await _authRepo.signInWithGoogle();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> forgotPassword(String email) async {
    try {
      await _authRepo.sendPasswordResetEmail(email);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> logOut() async {
    try {
      await _authRepo.logOut();
    } catch (e) {
      rethrow;
    }
  }

  // --- User Profile Actions ---
  Future<void> updateProfile({required String fullName, String? imagePath}) async {
    if (_currentUser == null) return;
    try {
      String? photoUrl = _currentUser!.photoUrl;
      if (imagePath != null) {
        // Upload photo and get new URL
        photoUrl = await _storageRepo.uploadProfilePicture(_currentUser!.uid, imagePath);
      }
      final updatedUser = _currentUser!.copyWith(
        fullName: fullName,
        photoUrl: photoUrl,
        updatedAt: DateTime.now(),
      );
      await _userRepo.updateUser(updatedUser);
    } catch (e) {
      rethrow;
    }
  }

  // --- Events Actions ---
  Future<void> addEvent(JoinMeEvent event) async {
    try {
      // In a real flow, event contains the correct organizerId. Let's make sure
      final eventWithHost = event.copyWith(
        organizerId: _currentUser?.uid ?? '',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await _eventRepo.createEvent(eventWithHost);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> createNewEvent({
    required String title,
    required String category,
    required double lat,
    required double lng,
    required String locationName,
    required int maxParticipants,
    required int duration,
    String? description,
    String? localImagePath,
  }) async {
    if (_currentUser == null) return;
    try {
      final eventId = FirebaseFirestore.instance.collection('events').doc().id;
      
      String? imageUrl;
      if (localImagePath != null) {
        imageUrl = await _storageRepo.uploadEventImage(eventId, localImagePath);
      }

      final avatarText = _currentUser!.fullName.isNotEmpty
          ? _currentUser!.fullName.split(' ').map((e) => e[0]).take(2).join().toUpperCase()
          : 'US';

      final newEvent = JoinMeEvent(
        id: eventId,
        title: title,
        category: category,
        organizerId: _currentUser!.uid,
        host: EventHost(
          name: _currentUser!.fullName,
          avatar: avatarText,
          reliability: _currentUser!.reliability,
        ),
        location: EventLocation(lat: lat, lng: lng, name: locationName),
        participants: 1,
        maxParticipants: maxParticipants,
        timeRemaining: 60, // starting countdown placeholder
        duration: duration,
        description: description,
        participantAvatars: [avatarText],
        imageUrl: imageUrl,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _eventRepo.createEvent(newEvent);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> joinEvent(String eventId) async {
    if (_currentUser == null) return;
    try {
      await _eventRepo.joinEvent(eventId, _currentUser!);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> leaveEvent(String eventId) async {
    if (_currentUser == null) return;
    try {
      await _eventRepo.leaveEvent(eventId, _currentUser!);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> toggleFavorite(String eventId) async {
    if (_currentUser == null) return;
    final isFav = _favoriteEventIds.contains(eventId);
    try {
      await _eventRepo.toggleFavorite(_currentUser!.uid, eventId, !isFav);
    } catch (e) {
      rethrow;
    }
  }

  // --- Notifications Actions ---
  Future<void> markNotificationAsRead(String noteId) async {
    try {
      await _notificationRepo.markAsRead(noteId);
    } catch (e) {
      rethrow;
    }
  }

  // --- Chat Actions ---
  Stream<List<Map<String, dynamic>>> streamEventMessages(String eventId) {
    return _eventRepo.streamMessages(eventId);
  }

  Future<void> sendEventMessage(String eventId, String text) async {
    if (_currentUser == null) return;
    try {
      final avatarText = _currentUser!.fullName.isNotEmpty
          ? _currentUser!.fullName.split(' ').map((e) => e[0]).take(2).join().toUpperCase()
          : 'US';
      await _eventRepo.sendMessage(eventId, _currentUser!.uid, _currentUser!.fullName, avatarText, text);
    } catch (e) {
      rethrow;
    }
  }
}

class PickedLocation {
  final double lat;
  final double lng;
  final String name;

  PickedLocation({required this.lat, required this.lng, required this.name});
}
