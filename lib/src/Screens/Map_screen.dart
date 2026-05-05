import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_marker_popup/flutter_map_marker_popup.dart';
import 'package:glassmorphism/glassmorphism.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:joinme/src/Screens/NavText.dart';
import 'package:joinme/src/Screens/event_detail_screen.dart';
import 'package:joinme/src/models/event.dart';
import 'package:joinme/src/services/app_state.dart';

final mapController = MapController();
final PopupController popupController = PopupController();

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  EventModel? _selectedEvent;
  Marker? _userPin;
  String? _locationName;
  final Map<Marker, EventModel> _markerEvent = {};
  List<Marker> _eventMarkers = [];
  LatLng _mapCenter = const LatLng(9.03, 38.74);
  double _mapZoom = 13;

  @override
  void initState() {
    super.initState();
    appState.addListener(_refreshMarkers);
    _refreshMarkers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _locationController.dispose();
    appState.removeListener(_refreshMarkers);
    super.dispose();
  }

  void _refreshMarkers() {
    _markerEvent.clear();
    _eventMarkers = appState.events.map((event) {
      late final Marker marker;
      marker = Marker(
        point: event.location,
        width: 52,
        height: 64,
        child: GestureDetector(
          onTap: () {
            setState(() {
              _selectedEvent = event;
            });
            popupController.togglePopup(marker);
          },
          child: Column(
            children: [
              Icon(Icons.place, size: _selectedEvent?.id == event.id ? 44 : 38, color: Color(event.category.colorValue)),
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(color: Color(event.category.colorValue), shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.18), blurRadius: 8)]),
              ),
            ],
          ),
        ),
      );
      _markerEvent[marker] = event;
      return marker;
    }).toList();

    if (_userPin != null) {
      _eventMarkers.add(_userPin!);
    }
    setState(() {});
  }

  Future<void> _fetchPlaceName(LatLng point) async {
    final url = 'https://nominatim.openstreetmap.org/reverse?format=jsonv2&lat=${point.latitude}&lon=${point.longitude}';
    final response = await http.get(Uri.parse(url), headers: {'User-Agent': 'JoinMe-App'});
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      setState(() {
        _locationName = data['display_name'] ?? data['name'] ?? data['address']?['road'];
      });
    }
  }

  void _onMapLongPress(TapPosition tapPosition, LatLng point) async {
    setState(() {
      _locationName = null;
      _selectedEvent = null;
      _mapCenter = point;
      _mapZoom = 15;
      _userPin = Marker(
        point: point,
        width: 64,
        height: 64,
        child: const Icon(Icons.location_on, size: 56, color: Color(0xFFF59E0B)),
      );
    });
    await _fetchPlaceName(point);
    _refreshMarkers();
    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Location picked', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Text(_locationName ?? 'Custom location', style: Theme.of(context).textTheme.bodyLarge),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.pushNamed(context, '/create'),
                style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(52), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                child: const Text('Create event at this spot'),
              ),
            ],
          ),
        );
      },
    );
  }

  void _onSearchEvents(String query) {
    appState.setSearchQuery(query);
    _refreshMarkers();
  }

  void _selectCategory(EventCategory? category) {
    appState.setFilterCategory(category);
    _refreshMarkers();
  }

  EventModel? get _previewEvent => _selectedEvent ?? (appState.events.isNotEmpty ? appState.events.first : null);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          Positioned.fill(
            child: FlutterMap(
              mapController: mapController,
              options: MapOptions(
                initialCenter: _mapCenter,
                initialZoom: _mapZoom,
                onLongPress: _onMapLongPress,
                onPositionChanged: (position, hasGesture) {
                  setState(() {
                    _mapCenter = position.center;
                    _mapZoom = position.zoom;
                  });
                },
              ),
              children: [
                TileLayer(urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png', userAgentPackageName: 'com.example.joinme'),
                MarkerLayer(markers: _eventMarkers),
              ],
            ),
          ),
          Positioned(top: 0, left: 0, right: 0, child: SafeArea(child: Align(child: const TopBar()))),
          Positioned(
            top: 70,
            left: 16,
            right: 16,
            child: GlassmorphicContainer(
              width: double.infinity,
              height: 58,
              borderRadius: 20,
              blur: 16,
              alignment: Alignment.center,
              border: 1,
              linearGradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Colors.white.withOpacity(0.22), Colors.white.withOpacity(0.08)],
              ),
              borderGradient: LinearGradient(colors: [Colors.white.withOpacity(0.5), Colors.white.withOpacity(0.1)]),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Search nearby events',
                        prefixIcon: const Icon(Icons.search),
                        border: InputBorder.none,
                      ),
                      onSubmitted: _onSearchEvents,
                    ),
                  ),
                  IconButton(
                    onPressed: () => _onSearchEvents(_searchController.text),
                    icon: const Icon(Icons.arrow_forward_ios, size: 18),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            top: 140,
            left: 16,
            right: 16,
            child: SizedBox(
              height: 52,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _buildCategoryChip(null, 'All', Colors.grey),
                  ...EventCategory.values.map((category) => _buildCategoryChip(category, category.label, Color(category.colorValue))).toList(),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: 20,
            left: 16,
            right: 16,
            child: _previewEvent == null
                ? const SizedBox()
                : GestureDetector(
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => EventDetailScreen(event: _previewEvent!))),
                    child: GlassmorphicContainer(
                      width: double.infinity,
                      height: 170,
                      borderRadius: 24,
                      blur: 16,
                      alignment: Alignment.center,
                      border: 1,
                      linearGradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Colors.white.withOpacity(0.22), Colors.white.withOpacity(0.08)],
                      ),
                      borderGradient: LinearGradient(colors: [Colors.white.withOpacity(0.5), Colors.white.withOpacity(0.1)]),
                      child: Padding(
                        padding: const EdgeInsets.all(18.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  decoration: BoxDecoration(color: Color(_previewEvent!.category.colorValue).withOpacity(0.15), borderRadius: BorderRadius.circular(14)),
                                  padding: const EdgeInsets.all(10),
                                  child: Text(_previewEvent!.category.icon, style: const TextStyle(fontSize: 24)),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Text(_previewEvent!.title, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontSize: 18, fontWeight: FontWeight.w700)),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  decoration: BoxDecoration(color: Color(_previewEvent!.category.colorValue).withOpacity(0.14), borderRadius: BorderRadius.circular(16)),
                                  child: Text(_previewEvent!.category.label, style: TextStyle(color: Color(_previewEvent!.category.colorValue), fontWeight: FontWeight.bold)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(_previewEvent!.description, maxLines: 2, overflow: TextOverflow.ellipsis),
                            const Spacer(),
                            Row(
                              children: [
                                Icon(Icons.calendar_today, size: 18, color: Theme.of(context).colorScheme.primary),
                                const SizedBox(width: 6),
                                Text('${_previewEvent!.dateTime.month}/${_previewEvent!.dateTime.day} ${_previewEvent!.dateTime.hour.toString().padLeft(2, '0')}:${_previewEvent!.dateTime.minute.toString().padLeft(2, '0')}', style: Theme.of(context).textTheme.bodySmall),
                                const Spacer(),
                                Text('${_previewEvent!.participantsCount}/${_previewEvent!.maxParticipants} going', style: Theme.of(context).textTheme.bodySmall),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
          ),
          Positioned(
            bottom: 30,
            right: 18,
            child: Column(
              children: [
                FloatingActionButton.small(
                  heroTag: 'zoomIn',
                  onPressed: () => setState(() {
                    _mapZoom += 1;
                    mapController.move(_mapCenter, _mapZoom);
                  }),
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                  child: const Icon(Icons.add),
                ),
                const SizedBox(height: 10),
                FloatingActionButton.small(
                  heroTag: 'zoomOut',
                  onPressed: () => setState(() {
                    _mapZoom = (_mapZoom - 1).clamp(1, 19);
                    mapController.move(_mapCenter, _mapZoom);
                  }),
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                  child: const Icon(Icons.remove),
                ),
                const SizedBox(height: 10),
                FloatingActionButton.small(
                  heroTag: 'recenter',
                  onPressed: () => setState(() {
                    _mapCenter = const LatLng(9.03, 38.74);
                    _mapZoom = 13;
                    mapController.move(_mapCenter, _mapZoom);
                  }),
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                  child: const Icon(Icons.my_location),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChip(EventCategory? category, String label, Color color) {
    final selected = appState.selectedCategory == category;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        selectedColor: color.withOpacity(0.2),
        backgroundColor: Theme.of(context).colorScheme.surface,
        labelStyle: TextStyle(color: selected ? color : Theme.of(context).textTheme.bodyLarge?.color),
        onSelected: (_) => _selectCategory(category),
      ),
    );
  }
}
