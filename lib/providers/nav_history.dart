/// One visited screen, with what it was showing.
class NavEntry {
  final String screen;
  final String? eventId;
  final String? groupId;
  final Map<String, dynamic>? friendData;

  const NavEntry(this.screen, {this.eventId, this.groupId, this.friendData});
}

/// Back-button history for AppState's screen-name navigation.
class NavHistory {
  static const maxDepth = 20;

  /// Screens that start a fresh history: back from them leaves the app.
  static const _roots = {'map', 'login', 'onboarding', 'resetPassword', 'restoreAccount'};

  /// Screens that are never returned to with back.
  static const _transient = {'login', 'onboarding', 'resetPassword', 'restoreAccount'};

  final List<NavEntry> _stack = [];

  bool get canGoBack => _stack.isNotEmpty;

  /// Records [current] as we move to [next]. With [replace], [current] is
  /// dropped from history (e.g. the Create form once the event exists).
  void push(NavEntry current, {required String next, bool replace = false}) {
    if (_roots.contains(next)) {
      _stack.clear();
      return;
    }
    if (replace || next == current.screen || _transient.contains(current.screen)) return;
    // An in-app back arrow to the screen we came from is a "back", not a new step.
    if (_stack.isNotEmpty && _stack.last.screen == next) {
      _stack.removeLast();
      return;
    }
    _stack.add(current);
    if (_stack.length > maxDepth) _stack.removeAt(0);
  }

  NavEntry? pop() => _stack.isEmpty ? null : _stack.removeLast();

  void clear() => _stack.clear();
}
