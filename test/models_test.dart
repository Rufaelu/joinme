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

  group('canRate', () {
    final endsAt = DateTime(2026, 10, 26, 12);
    final after = endsAt.add(const Duration(minutes: 1));

    test('member who has not rated can rate after the end', () {
      expect(canRate(endsAt: endsAt, now: after, isMember: true, alreadyRated: false), isTrue);
    });
    test('cannot rate before the event ends', () {
      expect(canRate(endsAt: endsAt, now: endsAt.subtract(const Duration(minutes: 1)), isMember: true, alreadyRated: false), isFalse);
    });
    test('non-members cannot rate', () {
      expect(canRate(endsAt: endsAt, now: after, isMember: false, alreadyRated: false), isFalse);
    });
    test('cannot rate twice', () {
      expect(canRate(endsAt: endsAt, now: after, isMember: true, alreadyRated: true), isFalse);
    });
  });

  group('visibleEvents', () {
    final now = DateTime.now();
    JoinMeEvent ev(String id, String title, {Duration endsIn = const Duration(hours: 1)}) {
      final row = feedRow(startsAt: now.subtract(const Duration(hours: 2)), endsAt: now.add(endsIn))
        ..['id'] = id
        ..['title'] = title;
      return JoinMeEvent.fromFeed(row);
    }

    test('hides events that have ended since they were fetched', () {
      final events = [ev('1', 'Football'), ev('2', 'Old', endsIn: const Duration(minutes: -1))];
      expect(visibleEvents(events, '').map((e) => e.id), ['1']);
    });
    test('filters by title, location or category, ignoring case', () {
      final events = [ev('1', 'Football'), ev('2', 'Study Jam')];
      expect(visibleEvents(events, 'STUDY').map((e) => e.id), ['2']);
      expect(visibleEvents(events, 'meskel').map((e) => e.id), ['1', '2']);
    });
  });

  group('photos', () {
    test('event feed row carries cover image and host avatar', () {
      final now = DateTime.now();
      final row = feedRow(startsAt: now, endsAt: now.add(const Duration(hours: 1)))
        ..['image_url'] = 'https://x/cover.jpg'
        ..['host_avatar_url'] = 'https://x/a.jpg';
      final e = JoinMeEvent.fromFeed(row);
      expect(e.imageUrl, 'https://x/cover.jpg');
      expect(e.host.avatarUrl, 'https://x/a.jpg');
    });
    test('photos are optional', () {
      final now = DateTime.now();
      final e = JoinMeEvent.fromFeed(feedRow(startsAt: now, endsAt: now.add(const Duration(hours: 1))));
      expect(e.imageUrl, isNull);
      expect(e.host.avatarUrl, isNull);
    });
    test('profile carries avatar url', () {
      final p = Profile.fromStats({'id': 'u1', 'name': 'Edna', 'avatar_url': 'https://x/e.jpg'});
      expect(p.avatarUrl, 'https://x/e.jpg');
    });
    test('upload path starts with the user id folder (storage rules rely on it)', () {
      final path = uploadPath(userId: 'u1', kind: 'avatar', extension: 'PNG');
      expect(path, startsWith('u1/avatar-'));
      expect(path, endsWith('.png'));
    });
  });

  group('canCancel', () {
    final start = DateTime(2026, 10, 26, 12);
    test('host can cancel before the start', () {
      expect(canCancel(isHost: true, startsAt: start, now: start.subtract(const Duration(minutes: 1))), isTrue);
    });
    test('host cannot cancel once started', () {
      expect(canCancel(isHost: true, startsAt: start, now: start), isFalse);
    });
    test('others cannot cancel', () {
      expect(canCancel(isHost: false, startsAt: start, now: start.subtract(const Duration(hours: 1))), isFalse);
    });
  });
}
