import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/event_model.dart';
import '../models/user_model.dart';
import '../models/participant_model.dart';

class EventRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _eventsCollection =>
      _firestore.collection('events');

  CollectionReference<Map<String, dynamic>> _participantsCollection(
          String eventId) =>
      _eventsCollection.doc(eventId).collection('participants');

  CollectionReference<Map<String, dynamic>> _favoritesCollection(
          String userId) =>
      _firestore.collection('users').doc(userId).collection('favorites');

  Future<void> createEvent(JoinMeEvent event) async {
    try {
      await _eventsCollection.doc(event.id).set(event.toJson());
      // Also add the host as the first participant
      final hostAvatar = event.host.avatar.isNotEmpty ? event.host.avatar : 'AN';
      await _participantsCollection(event.id).doc(event.host.name).set({
        'userId': event.organizerId,
        'fullName': event.host.name,
        'avatar': hostAvatar,
        'joinedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to create event: $e');
    }
  }

  Future<void> updateEvent(JoinMeEvent event) async {
    try {
      await _eventsCollection.doc(event.id).update(event.toJson());
    } catch (e) {
      throw Exception('Failed to update event: $e');
    }
  }

  Future<void> deleteEvent(String eventId) async {
    try {
      // Subcollections are not automatically deleted with document delete, but for simple app is fine
      await _eventsCollection.doc(eventId).delete();
    } catch (e) {
      throw Exception('Failed to delete event: $e');
    }
  }

  Stream<List<JoinMeEvent>> streamEvents() {
    return _eventsCollection
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => JoinMeEvent.fromJson(doc.data(), doc.id))
          .toList();
    });
  }

  Future<void> joinEvent(String eventId, UserModel user) async {
    final eventRef = _eventsCollection.doc(eventId);
    final participantRef = _participantsCollection(eventId).doc(user.uid);

    final avatarText = user.fullName.isNotEmpty
        ? user.fullName.split(' ').map((e) => e[0]).take(2).join().toUpperCase()
        : 'US';

    try {
      await _firestore.runTransaction((transaction) async {
        final eventSnap = await transaction.get(eventRef);
        if (!eventSnap.exists) {
          throw Exception('Event does not exist');
        }

        final event = JoinMeEvent.fromJson(eventSnap.data()!, eventSnap.id);
        if (event.participantAvatars.contains(avatarText)) {
          // Already joined
          return;
        }

        if (event.participants >= event.maxParticipants) {
          throw Exception('Event is already full');
        }

        // Add to participants subcollection
        transaction.set(participantRef, {
          'userId': user.uid,
          'fullName': user.fullName,
          'avatar': avatarText,
          'joinedAt': FieldValue.serverTimestamp(),
        });

        // Update event fields
        final updatedAvatars = List<String>.from(event.participantAvatars)..add(avatarText);
        transaction.update(eventRef, {
          'participants': event.participants + 1,
          'participantAvatars': updatedAvatars,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      });
    } catch (e) {
      throw Exception('Failed to join event: $e');
    }
  }

  Future<void> leaveEvent(String eventId, UserModel user) async {
    final eventRef = _eventsCollection.doc(eventId);
    final participantRef = _participantsCollection(eventId).doc(user.uid);

    final avatarText = user.fullName.isNotEmpty
        ? user.fullName.split(' ').map((e) => e[0]).take(2).join().toUpperCase()
        : 'US';

    try {
      await _firestore.runTransaction((transaction) async {
        final eventSnap = await transaction.get(eventRef);
        if (!eventSnap.exists) {
          throw Exception('Event does not exist');
        }

        final event = JoinMeEvent.fromJson(eventSnap.data()!, eventSnap.id);

        // Remove participant
        transaction.delete(participantRef);

        // Update event fields
        final updatedAvatars = List<String>.from(event.participantAvatars)..remove(avatarText);
        transaction.update(eventRef, {
          'participants': (event.participants - 1).clamp(0, event.maxParticipants),
          'participantAvatars': updatedAvatars,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      });
    } catch (e) {
      throw Exception('Failed to leave event: $e');
    }
  }

  Stream<List<ParticipantModel>> streamParticipants(String eventId) {
    return _participantsCollection(eventId)
        .orderBy('joinedAt', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => ParticipantModel.fromJson(doc.data()))
          .toList();
    });
  }

  Future<void> toggleFavorite(String userId, String eventId, bool isFavorite) async {
    try {
      final favRef = _favoritesCollection(userId).doc(eventId);
      if (isFavorite) {
        await favRef.set({
          'eventId': eventId,
          'addedAt': FieldValue.serverTimestamp(),
        });
      } else {
        await favRef.delete();
      }
    } catch (e) {
      throw Exception('Failed to update favorites: $e');
    }
  }

  Stream<List<String>> streamFavorites(String userId) {
    return _favoritesCollection(userId)
        .orderBy('addedAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => doc.id).toList();
    });
  }

  Stream<List<Map<String, dynamic>>> streamMessages(String eventId) {
    return _eventsCollection
        .doc(eventId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    });
  }

  Future<void> sendMessage(String eventId, String senderId, String senderName, String senderAvatar, String text) async {
    try {
      await _eventsCollection.doc(eventId).collection('messages').add({
        'senderId': senderId,
        'senderName': senderName,
        'senderAvatar': senderAvatar,
        'message': text,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to send message: $e');
    }
  }
}
