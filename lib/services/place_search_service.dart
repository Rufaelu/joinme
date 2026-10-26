import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/social.dart';

/// Place search via OpenStreetMap Nominatim (free; max ~1 request/second,
/// so callers debounce typing).
class PlaceSearchService {
  Future<List<PlaceResult>> search(String query, {double? nearLat, double? nearLng}) async {
    final q = query.trim();
    if (q.length < 3) return [];
    final params = {
      'format': 'json',
      'q': q,
      'limit': '6',
      'accept-language': 'en',
      // Prefer results near the map's centre without excluding the rest.
      if (nearLat != null && nearLng != null)
        'viewbox': '${nearLng - 0.3},${nearLat + 0.3},${nearLng + 0.3},${nearLat - 0.3}',
    };
    final res = await http.get(
      Uri.https('nominatim.openstreetmap.org', '/search', params),
      headers: {'User-Agent': 'joinme_app'},
    );
    if (res.statusCode != 200) return [];
    final rows = (json.decode(res.body) as List).cast<Map<String, dynamic>>();
    return rows.map(PlaceResult.fromNominatim).toList();
  }
}
