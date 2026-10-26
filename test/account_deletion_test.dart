import 'package:flutter_test/flutter_test.dart';
import 'package:joinme/models/models.dart';
import 'package:joinme/models/social.dart';

void main() {
  final deletedAt = DateTime(2026, 10, 1, 12);

  group('shownName', () {
    test('active accounts show their name', () {
      expect(shownName('Abel T.', null), 'Abel T.');
    });
    test('deleted accounts are labelled', () {
      expect(shownName('Abel T.', deletedAt), 'Abel T. · Deleted account');
    });
  });

  group('canRestore', () {
    test('within 30 days', () {
      expect(canRestore(deletedAt, deletedAt.add(const Duration(days: 29))), isTrue);
    });
    test('after 30 days', () {
      expect(canRestore(deletedAt, deletedAt.add(const Duration(days: 31))), isFalse);
    });
  });

  test('profile reads deleted_at', () {
    final p = Profile.fromStats({'id': 'u1', 'name': 'Abel', 'deleted_at': '2026-10-01T12:00:00Z'});
    expect(p.isDeleted, isTrue);
    expect(Profile.fromStats({'id': 'u1', 'name': 'Abel'}).isDeleted, isFalse);
  });

  test('person reads deleted_at', () {
    final p = Person.fromStats({'id': 'u1', 'name': 'Abel', 'deleted_at': '2026-10-01T12:00:00Z'});
    expect(p.isDeleted, isTrue);
    expect(p.displayName, 'Abel · Deleted account');
  });

  test('account notifications stay on the Activity screen', () {
    expect(notificationScreen('account_deleted'), 'notifications');
    expect(notificationScreen('account_restored'), 'notifications');
  });
}
