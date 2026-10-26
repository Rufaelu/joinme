import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/models.dart';

const minDurationMinutes = 15;
const maxDurationMinutes = 24 * 60;

/// "45m", "2h", "1h 45m".
String formatDuration(int minutes) {
  final h = minutes ~/ 60, m = minutes % 60;
  if (h == 0) return '${m}m';
  return m == 0 ? '${h}h' : '${h}h ${m}m';
}

class EventDraft {
  final String title;
  final String category;
  final String? description;
  final String? locationName;
  final double? lat;
  final double? lng;
  final DateTime startsAt;
  final int durationMinutes;
  final int groupSize;
  final String? imageUrl;

  EventDraft({
    required this.title,
    required this.category,
    required this.description,
    required this.locationName,
    required this.lat,
    required this.lng,
    required this.startsAt,
    required this.durationMinutes,
    required this.groupSize,
    this.imageUrl,
  });

  /// Returns an error message, or null when the draft can be saved.
  String? validate(DateTime now) {
    if (title.trim().isEmpty) return 'Add a title';
    if (locationName == null || lat == null || lng == null) return 'Pick a location on the map';
    if (groupSize < 2 || groupSize > 50) return 'Group size must be 2–50';
    if (durationMinutes < minDurationMinutes || durationMinutes > maxDurationMinutes) {
      return 'Duration must be between 15 minutes and 24 hours';
    }
    if (startsAt.isBefore(now.subtract(const Duration(minutes: 5)))) return 'Start time is in the past';
    return null;
  }

  Map<String, dynamic> toInsert() {
    final desc = description?.trim();
    return {
      'title': title.trim(),
      'category': category,
      'description': (desc == null || desc.isEmpty) ? null : desc,
      'location_name': locationName,
      'lat': lat,
      'lng': lng,
      'starts_at': startsAt.toUtc().toIso8601String(),
      'ends_at': startsAt.add(Duration(minutes: durationMinutes)).toUtc().toIso8601String(),
      'group_size': groupSize,
      if (imageUrl != null) 'image_url': imageUrl,
    };
  }
}

class EventService {
  SupabaseClient get _db => Supabase.instance.client;

  Future<List<JoinMeEvent>> fetchActive() async {
    final rows = await _db
        .from('event_feed')
        .select()
        .gt('ends_at', DateTime.now().toUtc().toIso8601String())
        .order('starts_at');
    return rows.map(JoinMeEvent.fromFeed).toList();
  }

  Future<JoinMeEvent> fetchOne(String id) async {
    final row = await _db.from('event_feed').select().eq('id', id).single();
    return JoinMeEvent.fromFeed(row);
  }

  /// Saves the event and returns its id. The database adds the host to group 1.
  Future<String> create(EventDraft draft) async {
    final row = await _db.from('events').insert(draft.toInsert()).select('id').single();
    return row['id'] as String;
  }

  /// Cancels an event. The database only allows this for the host, before it starts.
  Future<void> cancel(String id) async {
    final deleted = await _db.from('events').delete().eq('id', id).select('id');
    if (deleted.isEmpty) throw Exception('This event has already started and can no longer be cancelled');
  }

  /// Calls [onChange] whenever events or group memberships change.
  RealtimeChannel subscribeChanges(void Function() onChange) {
    return _db
        .channel('event-feed')
        .onPostgresChanges(event: PostgresChangeEvent.all, schema: 'public', table: 'events', callback: (_) => onChange())
        .onPostgresChanges(event: PostgresChangeEvent.all, schema: 'public', table: 'group_members', callback: (_) => onChange())
        .subscribe();
  }
}
