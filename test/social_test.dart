import 'package:flutter_test/flutter_test.dart';
import 'package:joinme/models/social.dart';

void main() {
  const me = '11111111-1111-1111-1111-111111111111';
  const other = '99999999-9999-9999-9999-999999999999';

  group('pairKey', () {
    test('is the same whichever way round, smaller id first (matches the database)', () {
      expect(pairKey(me, other), '$me:$other');
      expect(pairKey(other, me), '$me:$other');
    });
  });

  group('relationFor', () {
    test('accepted means friends', () {
      expect(relationFor(requesterId: other, addresseeId: me, status: 'accepted', me: me), FriendRelation.friends);
    });
    test('pending request to me is incoming', () {
      expect(relationFor(requesterId: other, addresseeId: me, status: 'pending', me: me), FriendRelation.incoming);
    });
    test('pending request from me is outgoing', () {
      expect(relationFor(requesterId: me, addresseeId: other, status: 'pending', me: me), FriendRelation.outgoing);
    });
  });

  group('PlaceResult.fromNominatim', () {
    test('parses name, short label and coordinates', () {
      final p = PlaceResult.fromNominatim({
        'display_name': 'Bole, Addis Ababa, Ethiopia',
        'name': 'Bole',
        'lat': '8.9806',
        'lon': '38.7578',
      });
      expect(p.name, 'Bole');
      expect(p.subtitle, 'Addis Ababa, Ethiopia');
      expect(p.lat, closeTo(8.9806, 1e-9));
      expect(p.lng, closeTo(38.7578, 1e-9));
    });
    test('falls back to the first part of the address when name is empty', () {
      final p = PlaceResult.fromNominatim({
        'display_name': 'Meskel Square, Kirkos, Addis Ababa',
        'name': '',
        'lat': '9.01',
        'lon': '38.76',
      });
      expect(p.name, 'Meskel Square');
      expect(p.subtitle, 'Kirkos, Addis Ababa');
    });
  });

  group('AppNotification', () {
    test('parses a row', () {
      final n = AppNotification.fromMap({
        'id': 7,
        'type': 'friend_request',
        'actor_id': other,
        'event_id': null,
        'body': 'Edna sent you a friend request',
        'read': false,
        'created_at': '2026-10-26T10:00:00Z',
      });
      expect(n.id, 7);
      expect(n.type, 'friend_request');
      expect(n.actorId, other);
      expect(n.read, isFalse);
    });
    test('opens the right screen for each type', () {
      expect(notificationScreen('friend_request'), 'friends');
      expect(notificationScreen('friend_accepted'), 'directChat');
      expect(notificationScreen('direct_message'), 'directChat');
      expect(notificationScreen('event_joined'), 'event');
      expect(notificationScreen('something_else'), 'notifications');
    });
  });
}
