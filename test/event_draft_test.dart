import 'package:flutter_test/flutter_test.dart';
import 'package:joinme/services/event_service.dart';

void main() {
  final now = DateTime(2026, 10, 26, 12, 0);

  EventDraft draft({
    String title = 'Football',
    String? locationName = 'Meskel Square',
    double? lat = 9.01,
    double? lng = 38.76,
    DateTime? startsAt,
    int groupSize = 6,
    int durationMinutes = 60,
  }) {
    return EventDraft(
      title: title,
      category: 'sports',
      description: null,
      locationName: locationName,
      lat: lat,
      lng: lng,
      startsAt: startsAt ?? now.add(const Duration(minutes: 30)),
      durationMinutes: durationMinutes,
      groupSize: groupSize,
    );
  }

  group('EventDraft.validate', () {
    test('a complete draft is valid', () {
      expect(draft().validate(now), isNull);
    });
    test('empty title is rejected', () {
      expect(draft(title: '   ').validate(now), 'Add a title');
    });
    test('missing location is rejected', () {
      expect(draft(locationName: null, lat: null, lng: null).validate(now), 'Pick a location on the map');
    });
    test('group size below 2 is rejected', () {
      expect(draft(groupSize: 1).validate(now), 'Group size must be 2–50');
    });
    test('group size above 50 is rejected', () {
      expect(draft(groupSize: 51).validate(now), 'Group size must be 2–50');
    });
    test('start more than 5 minutes ago is rejected', () {
      expect(draft(startsAt: now.subtract(const Duration(minutes: 6))).validate(now), 'Start time is in the past');
    });
    test('duration under 15 minutes is rejected', () {
      expect(draft(durationMinutes: 10).validate(now), 'Duration must be between 15 minutes and 24 hours');
    });
    test('duration over 24 hours is rejected', () {
      expect(draft(durationMinutes: 24 * 60 + 1).validate(now), 'Duration must be between 15 minutes and 24 hours');
    });
    test('a custom 1h 45m duration is fine', () {
      expect(draft(durationMinutes: 105).validate(now), isNull);
    });
    test('start a couple of minutes ago is allowed', () {
      expect(draft(startsAt: now.subtract(const Duration(minutes: 2))).validate(now), isNull);
    });
  });

  test('toInsert computes ends_at from duration and trims text', () {
    final d = EventDraft(
      title: '  Football  ',
      category: 'sports',
      description: '  ',
      locationName: 'Meskel Square',
      lat: 9.01,
      lng: 38.76,
      startsAt: DateTime.utc(2026, 10, 26, 12),
      durationMinutes: 90,
      groupSize: 6,
    );
    final row = d.toInsert();
    expect(row['title'], 'Football');
    expect(row['description'], isNull);
    expect(row['starts_at'], '2026-10-26T12:00:00.000Z');
    expect(row['ends_at'], '2026-10-26T13:30:00.000Z');
    expect(row['group_size'], 6);
    expect(row.containsKey('host_id'), isFalse);
  });

  test('toInsert includes the cover image only when there is one', () {
    EventDraft withImage(String? url) => EventDraft(
          title: 'Football',
          category: 'sports',
          description: null,
          locationName: 'Meskel Square',
          lat: 9.01,
          lng: 38.76,
          startsAt: DateTime.utc(2026, 10, 26, 12),
          durationMinutes: 60,
          groupSize: 6,
          imageUrl: url,
        );
    expect(withImage('https://x/c.jpg').toInsert()['image_url'], 'https://x/c.jpg');
    expect(withImage(null).toInsert().containsKey('image_url'), isFalse);
  });

  group('formatDuration', () {
    test('minutes only', () => expect(formatDuration(45), '45m'));
    test('whole hours', () => expect(formatDuration(120), '2h'));
    test('hours and minutes', () => expect(formatDuration(105), '1h 45m'));
  });
}
