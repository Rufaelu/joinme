import 'package:flutter_test/flutter_test.dart';
import 'package:joinme/models/models.dart';

Map<String, dynamic> feedRow({
  required DateTime startsAt,
  required DateTime endsAt,
  double? hostReputation,
}) {
  return {
    'id': 'e1',
    'host_id': 'u1',
    'title': 'Pickup Football',
    'category': 'sports',
    'description': 'Friendly match',
    'location_name': 'Meskel Square',
    'lat': 9.01,
    'lng': 38.761,
    'starts_at': startsAt.toUtc().toIso8601String(),
    'ends_at': endsAt.toUtc().toIso8601String(),
    'group_size': 6,
    'created_at': DateTime.now().toUtc().toIso8601String(),
    'host_name': 'Rufael Melese',
    'host_reputation': hostReputation,
    'host_rating_count': 0,
    'member_count': 7,
    'group_count': 2,
  };
}

void main() {
  group('initialsOf', () {
    test('two words give two letters', () {
      expect(initialsOf('Rufael Melese'), 'RM');
    });
    test('one word gives one uppercase letter', () {
      expect(initialsOf('edna'), 'E');
    });
    test('blank name gives a question mark', () {
      expect(initialsOf('  '), '?');
    });
  });

  group('formatReputation', () {
    test('no ratings shows New', () {
      expect(formatReputation(null), 'New');
    });
    test('rounds to one decimal', () {
      expect(formatReputation(4.56), '4.6');
    });
  });

  group('JoinMeEvent.fromFeed', () {
    test('parses an upcoming event', () {
      final now = DateTime.now();
      final e = JoinMeEvent.fromFeed(feedRow(
        startsAt: now.add(const Duration(minutes: 30)),
        endsAt: now.add(const Duration(minutes: 120)),
      ));
      expect(e.timeRemaining, inInclusiveRange(29, 30));
      expect(e.duration, 90);
      expect(e.maxParticipants, 12);
      expect(e.participants, 7);
      expect(e.host.reputation, isNull);
      expect(e.host.name, 'Rufael Melese');
      expect(e.host.avatar, 'RM');
      expect(e.location.name, 'Meskel Square');
      expect(e.hasEnded, isFalse);
    });

    test('an event whose end is in the past has ended', () {
      final now = DateTime.now();
      final e = JoinMeEvent.fromFeed(feedRow(
        startsAt: now.subtract(const Duration(hours: 2)),
        endsAt: now.subtract(const Duration(hours: 1)),
        hostReputation: 4.5,
      ));
      expect(e.hasEnded, isTrue);
      expect(e.timeRemaining, 0);
      expect(e.host.reputation, 4.5);
    });

    test('host reputation sent as an int still parses', () {
      final now = DateTime.now();
      final row = feedRow(
        startsAt: now,
        endsAt: now.add(const Duration(hours: 1)),
      )..['host_reputation'] = 4;
      expect(JoinMeEvent.fromFeed(row).host.reputation, 4.0);
    });
  });
}
