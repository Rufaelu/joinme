import 'package:flutter_test/flutter_test.dart';
import 'package:joinme/providers/nav_history.dart';

void main() {
  NavEntry e(String screen, {String? eventId}) => NavEntry(screen, eventId: eventId);

  test('back returns to the previous screen with its event', () {
    final h = NavHistory();
    h.push(e('map'), next: 'event');
    h.push(e('event', eventId: 'e1'), next: 'chat');
    expect(h.pop()!.screen, 'event');
    expect(h.pop()!.screen, 'map');
    expect(h.pop(), isNull);
  });

  test('going to the map starts over, so back from the map exits', () {
    final h = NavHistory();
    h.push(e('map'), next: 'profile');
    h.push(e('profile'), next: 'map');
    expect(h.canGoBack, isFalse);
  });

  test('login, onboarding and password reset are not kept', () {
    final h = NavHistory();
    h.push(e('login'), next: 'onboarding');
    expect(h.canGoBack, isFalse);
    h.push(e('onboarding'), next: 'map');
    expect(h.canGoBack, isFalse);
  });

  test("an in-app back arrow to the previous screen counts as going back (no loop)", () {
    final h = NavHistory();
    h.push(e('map'), next: 'event');
    h.push(e('event', eventId: 'e1'), next: 'chat');
    // chat's arrow navigates to 'event', which is the previous screen
    h.push(e('chat'), next: 'event');
    expect(h.pop()!.screen, 'map');
  });

  test('re-opening the same screen does not stack duplicates', () {
    final h = NavHistory();
    h.push(e('map'), next: 'notifications');
    h.push(e('notifications'), next: 'notifications');
    expect(h.pop()!.screen, 'map');
  });

  test('history is capped', () {
    final h = NavHistory();
    for (var i = 0; i < 50; i++) {
      h.push(e(i.isEven ? 'event' : 'chat', eventId: '$i'), next: i.isEven ? 'chat' : 'event');
    }
    var count = 0;
    while (h.pop() != null) {
      count++;
    }
    expect(count, lessThanOrEqualTo(NavHistory.maxDepth));
  });

  test('replacing a screen (create → new event) skips it on back', () {
    final h = NavHistory();
    h.push(e('map'), next: 'create');
    h.push(e('create'), next: 'event', replace: true);
    expect(h.pop()!.screen, 'map');
    expect(h.pop(), isNull);
  });
}
