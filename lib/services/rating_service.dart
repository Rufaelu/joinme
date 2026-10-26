import 'package:supabase_flutter/supabase_flutter.dart';

class PastEvent {
  final String eventId;
  final String title;
  final String category;
  final DateTime endedAt;
  final bool rated;

  PastEvent({
    required this.eventId,
    required this.title,
    required this.category,
    required this.endedAt,
    required this.rated,
  });
}

class RatingService {
  SupabaseClient get _db => Supabase.instance.client;
  String? get _uid => _db.auth.currentUser?.id;

  Future<bool> hasRated(String eventId) async {
    final uid = _uid;
    if (uid == null) return false;
    final row = await _db
        .from('event_ratings')
        .select('event_id')
        .eq('event_id', eventId)
        .eq('rater_id', uid)
        .maybeSingle();
    return row != null;
  }

  /// [hostScore] is null when the current user is the host.
  /// [peerScores] maps a group mate's user id to a 1–5 score.
  Future<void> submit({
    required String eventId,
    required int eventScore,
    required int? hostScore,
    required Map<String, int> peerScores,
  }) async {
    await _db.from('event_ratings').insert({
      'event_id': eventId,
      'event_score': eventScore,
      'host_score': hostScore,
    });
    if (peerScores.isNotEmpty) {
      await _db.from('user_ratings').insert([
        for (final e in peerScores.entries) {'event_id': eventId, 'ratee_id': e.key, 'score': e.value},
      ]);
    }
  }

  /// Events I was in (as host or member) that have ended, newest first.
  Future<List<PastEvent>> myPastEvents() async {
    final uid = _uid;
    if (uid == null) return [];
    final rows = await _db
        .from('group_members')
        .select('event_groups(events(id, title, category, ends_at))')
        .eq('user_id', uid);
    final rated = (await _db.from('event_ratings').select('event_id').eq('rater_id', uid))
        .map((r) => r['event_id'] as String)
        .toSet();

    final now = DateTime.now();
    final byId = <String, PastEvent>{};
    for (final r in rows) {
      final ev = (r['event_groups'] as Map<String, dynamic>)['events'] as Map<String, dynamic>;
      final endedAt = DateTime.parse(ev['ends_at'] as String).toLocal();
      if (endedAt.isAfter(now)) continue;
      final id = ev['id'] as String;
      byId[id] = PastEvent(
        eventId: id,
        title: ev['title'] as String,
        category: ev['category'] as String,
        endedAt: endedAt,
        rated: rated.contains(id),
      );
    }
    return byId.values.toList()..sort((a, b) => b.endedAt.compareTo(a.endedAt));
  }
}
