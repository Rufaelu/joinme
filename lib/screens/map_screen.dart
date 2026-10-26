import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:geolocator/geolocator.dart';
import '../providers/app_state.dart';
import '../theme/app_theme.dart';
import '../models/models.dart';
import '../widgets/glass_container.dart';
import '../widgets/bottom_nav.dart';
import '../widgets/avatar.dart';
import '../widgets/joinme_logo.dart';
import '../models/social.dart';
import '../services/place_search_service.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({Key? key}) : super(key: key);

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  JoinMeEvent? _selectedEvent;
  String _searchQuery = '';

  // Place search
  final MapController _mapController = MapController();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();
  final PlaceSearchService _places = PlaceSearchService();
  Timer? _placeDebounce;
  List<PlaceResult> _placeResults = [];
  bool _placesLoading = false;
  PlaceResult? _pickedPlace;
  
  // Addis Ababa coordinates as default
  LatLng _currentLocation = const LatLng(9.0300, 38.7400);
  bool _isLoadingLocation = true;
  // Rebuild every minute so "starts in" labels update and ended events drop off.
  Timer? _ticker;
  
  // Emojis for categories
  final Map<String, String> _categoryEmojis = {
    'sports': '⚽',
    'study': '📚',
    'chill': '☕',
    'creative': '🎨',
  };

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppState>().refreshEvents();
    });
    _determinePosition();
    _searchFocus.addListener(() {
      if (mounted) setState(() {});
    });
    _ticker = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _placeDebounce?.cancel();
    _searchController.dispose();
    _searchFocus.dispose();
    _mapController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    setState(() => _searchQuery = value);
    _placeDebounce?.cancel();
    if (value.trim().length < 3) {
      setState(() => _placeResults = []);
      return;
    }
    // Nominatim allows about one request a second, so wait until typing pauses.
    _placeDebounce = Timer(const Duration(milliseconds: 600), () => _searchPlaces(value));
  }

  Future<void> _searchPlaces(String query) async {
    setState(() => _placesLoading = true);
    try {
      LatLng center = _currentLocation;
      try {
        center = _mapController.camera.center;
      } catch (_) {}
      final results = await _places.search(query, nearLat: center.latitude, nearLng: center.longitude);
      if (mounted && _searchQuery == query) setState(() => _placeResults = results);
    } catch (e) {
      debugPrint('Place search failed: $e');
    } finally {
      if (mounted) setState(() => _placesLoading = false);
    }
  }

  void _clearSearch() {
    _searchController.clear();
    _searchFocus.unfocus();
    _placeDebounce?.cancel();
    setState(() {
      _searchQuery = '';
      _placeResults = [];
    });
  }

  void _goToPlace(PlaceResult place) {
    _searchFocus.unfocus();
    setState(() {
      _pickedPlace = place;
      _selectedEvent = null;
      _placeResults = [];
      _searchQuery = '';
    });
    _searchController.text = place.name;
    _mapController.move(LatLng(place.lat, place.lng), 16);
  }

  void _goToEvent(JoinMeEvent event) {
    _searchFocus.unfocus();
    setState(() {
      _selectedEvent = event;
      _pickedPlace = null;
      _placeResults = [];
    });
    _mapController.move(LatLng(event.location.lat, event.location.lng), 15);
  }

  void _createAtPlace(PlaceResult place) {
    final appState = context.read<AppState>();
    appState.setPickedLocation(PickedLocation(lat: place.lat, lng: place.lng, name: place.name));
    appState.navigateTo('create');
  }

  Future<void> _determinePosition() async {
    try {
      bool serviceEnabled;
      LocationPermission permission;

      // Test if location services are enabled.
      serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) setState(() => _isLoadingLocation = false);
        return;
      }

      permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) setState(() => _isLoadingLocation = false);
          return;
        }
      }
      
      if (permission == LocationPermission.deniedForever) {
        if (mounted) setState(() => _isLoadingLocation = false);
        return;
      } 

      Position position = await Geolocator.getCurrentPosition();
      if (mounted) {
        setState(() {
          _currentLocation = LatLng(position.latitude, position.longitude);
          _isLoadingLocation = false;
        });
      }
    } catch (e) {
      // Catch MissingPluginException or any other errors and default gracefully
      debugPrint('Geolocation error: $e');
      if (mounted) setState(() => _isLoadingLocation = false);
    }
  }

  String _startLabel(JoinMeEvent event) {
    if (event.hasStarted) return 'Happening now';
    final m = event.timeRemaining;
    if (m < 60) return 'Starts in ${m}m';
    if (m < 60 * 24) return 'Starts in ${(m / 60).floor()}h ${m % 60}m';
    return 'Starts in ${(m / (60 * 24)).floor()}d';
  }

  void _handlePinClick(JoinMeEvent event) {
    setState(() {
      _selectedEvent = event;
    });
  }

  Future<void> _handleLongPress(TapPosition tapPosition, LatLng point) async {
    final appState = context.read<AppState>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    setState(() {
      _selectedEvent = null;
    });

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return FutureBuilder<http.Response>(
          future: http.get(Uri.parse(
            'https://nominatim.openstreetmap.org/reverse?format=json&lat=${point.latitude}&lon=${point.longitude}'
          ), headers: {
            'User-Agent': 'joinme_app'
          }),
          builder: (context, snapshot) {
            String locationName = 'Fetching location...';
            bool isLoading = true;

            if (snapshot.connectionState == ConnectionState.done) {
              isLoading = false;
              if (snapshot.hasData && snapshot.data!.statusCode == 200) {
                final data = json.decode(snapshot.data!.body);
                locationName = data['display_name'] ?? 'Unknown Location';
                // Take only the first two parts of the address for brevity
                final parts = locationName.split(', ');
                if (parts.length > 2) {
                  locationName = '${parts[0]}, ${parts[1]}';
                }
              } else {
                locationName = 'Unknown Location';
              }
            }

            return Container(
              margin: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isDark ? AppTheme.darkBg2 : Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  )
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 48,
                      height: 4,
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white24 : Colors.black12,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppTheme.accent.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(LucideIcons.mapPin, color: AppTheme.accentLight),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Selected Location',
                                style: TextStyle(
                                  color: isDark ? Colors.white54 : Colors.black54,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              if (isLoading)
                                const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              else
                                Text(
                                  locationName,
                                  style: TextStyle(
                                    color: isDark ? Colors.white : Colors.black,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    GestureDetector(
                      onTap: isLoading ? null : () {
                        appState.setPickedLocation(PickedLocation(
                          lat: point.latitude,
                          lng: point.longitude,
                          name: locationName,
                        ));
                        Navigator.pop(context);
                        appState.navigateTo('create');
                      },
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          color: isLoading ? (isDark ? Colors.white10 : Colors.black12) : AppTheme.primary,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Center(
                          child: Text(
                            appState.isPickingLocation ? 'Confirm Location' : 'Create Event Here',
                            style: TextStyle(
                              color: isLoading ? (isDark ? Colors.white54 : Colors.black54) : Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ).animate().slideY(begin: 1, end: 0, duration: 400.ms, curve: Curves.easeOutQuad);
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final appState = context.watch<AppState>();
    // While a place is picked the search box shows its name, so don't filter events by it.
    final shown = visibleEvents(appState.events, _pickedPlace == null ? _searchQuery : '');
    final eventMatches = _searchQuery.trim().isEmpty ? <JoinMeEvent>[] : shown.take(3).toList();
    final showResults = _searchFocus.hasFocus && (eventMatches.isNotEmpty || _placeResults.isNotEmpty || _placesLoading);
    // Keep the preview card in sync with refreshed data (or drop it if the event is gone).
    final selected = _selectedEvent == null
        ? null
        : shown.where((e) => e.id == _selectedEvent!.id).firstOrNull;
    
    return Scaffold(
      body: Stack(
        children: [
          // FlutterMap Background
          if (!_isLoadingLocation)
            FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: _currentLocation,
                initialZoom: 13.0,
                onTap: (tapPosition, point) {
                  _searchFocus.unfocus();
                  setState(() {
                    _selectedEvent = null;
                    _pickedPlace = null;
                  });
                },
                onLongPress: _handleLongPress,
              ),
            children: [
              if (isDark)
                ColorFiltered(
                  colorFilter: const ColorFilter.matrix([
                    -1,  0,  0, 0, 255,
                     0, -1,  0, 0, 255,
                     0,  0, -1, 0, 255,
                     0,  0,  0, 1,   0,
                  ]),
                  child: TileLayer(
                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.joinme.app',
                  ),
                )
              else
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.joinme.app',
                ),
              MarkerLayer(
                markers: shown.map((event) {
                  final isSelected = _selectedEvent?.id == event.id;
                  final categoryColor = AppTheme.colorsFor(event.category);
                  
                  return Marker(
                    point: LatLng(event.location.lat, event.location.lng),
                    width: 60,
                    height: 60,
                    child: GestureDetector(
                      onTap: () => _handlePinClick(event),
                      child: AnimatedScale(
                        scale: isSelected ? 1.2 : 1.0,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.elasticOut,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // Pin Shape background
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: categoryColor.primary,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: categoryColor.primary.withOpacity(0.5),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  )
                                ],
                              ),
                            ),
                            // Category Emoji
                            Text(
                              _categoryEmojis[event.category] ?? '📍',
                              style: const TextStyle(fontSize: 18),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              if (_pickedPlace != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: LatLng(_pickedPlace!.lat, _pickedPlace!.lng),
                      width: 48,
                      height: 48,
                      alignment: Alignment.topCenter,
                      child: const Icon(Icons.location_on, color: AppTheme.accent, size: 48),
                    ),
                  ],
                ),
            ],
          ),
          
          // Theme Toggle Overlay
          Positioned(
            top: 16,
            right: 16,
            child: SafeArea(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => context.read<AppState>().toggleTheme(),
                child: GlassContainer(
                  borderRadius: 30,
                  padding: const EdgeInsets.all(12),
                  child: Icon(
                    isDark ? LucideIcons.sun : LucideIcons.moon,
                    color: isDark ? AppTheme.primaryLight : AppTheme.accent,
                  ),
                ),
              ),
            ),
          ),

          // Header Overlay
          Positioned(
            top: 50,
            left: 0,
            right: 0,
            child: Center(
              child: GlassContainer(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                borderRadius: 30,
                child: const JoinMeLogo(size: 30),
              ),
            ),
          ),
          
          // Search Bar Overlay
          Positioned(
            top: 110,
            left: 16,
            right: 16,
            child: GlassContainer(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                children: [
                  Icon(LucideIcons.search, color: isDark ? Colors.white54 : Colors.black54),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      focusNode: _searchFocus,
                      onChanged: _onSearchChanged,
                      onTap: () => setState(() {}),
                      textInputAction: TextInputAction.search,
                      onSubmitted: (_) {
                        if (_placeResults.isNotEmpty) _goToPlace(_placeResults.first);
                      },
                      decoration: InputDecoration(
                        hintText: 'Search events or places...',
                        border: InputBorder.none,
                        hintStyle: TextStyle(color: isDark ? Colors.white54 : Colors.black54),
                      ),
                      style: TextStyle(color: isDark ? Colors.white : Colors.black),
                    ),
                  ),
                  if (_searchController.text.isNotEmpty)
                    GestureDetector(
                      onTap: () {
                        _clearSearch();
                        setState(() => _pickedPlace = null);
                      },
                      child: Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: Icon(LucideIcons.x, color: isDark ? Colors.white54 : Colors.black54, size: 20),
                      ),
                    ),
                  GestureDetector(
                    onTap: appState.loadingEvents ? null : () => appState.refreshEvents(),
                    child: appState.loadingEvents
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                        : Icon(LucideIcons.refreshCw, color: isDark ? Colors.white54 : Colors.black54),
                  ),
                ],
              ),
            ),
          ),

          // Search results: matching events, then places
          if (showResults)
            Positioned(
              top: 170,
              left: 16,
              right: 16,
              child: GlassContainer(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.45),
                  child: ListView(
                    shrinkWrap: true,
                    padding: EdgeInsets.zero,
                    children: [
                      ...eventMatches.map((e) => _resultTile(
                            isDark,
                            icon: LucideIcons.calendar,
                            color: AppTheme.colorsFor(e.category).primary,
                            title: e.title,
                            subtitle: 'Event · ${e.location.name}',
                            onTap: () => _goToEvent(e),
                          )),
                      ..._placeResults.map((p) => _resultTile(
                            isDark,
                            icon: LucideIcons.mapPin,
                            color: AppTheme.accent,
                            title: p.name,
                            subtitle: p.subtitle,
                            onTap: () => _goToPlace(p),
                          )),
                      if (_placesLoading)
                        const Padding(
                          padding: EdgeInsets.all(12),
                          child: Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))),
                        ),
                    ],
                  ),
                ),
              ),
            ),

          // Picked place card
          if (_pickedPlace != null && selected == null)
            Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: GlassContainer(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(LucideIcons.mapPin, color: AppTheme.accent),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(_pickedPlace!.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: isDark ? Colors.white : Colors.black)),
                              if (_pickedPlace!.subtitle.isNotEmpty)
                                Text(_pickedPlace!.subtitle,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(color: isDark ? Colors.white54 : Colors.black54, fontSize: 12)),
                            ],
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            _clearSearch();
                            setState(() => _pickedPlace = null);
                          },
                          child: Icon(LucideIcons.x, color: isDark ? Colors.white54 : Colors.black54),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    GestureDetector(
                      onTap: () => _createAtPlace(_pickedPlace!),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(color: AppTheme.primary, borderRadius: BorderRadius.circular(16)),
                        child: Center(
                          child: Text(
                            appState.isPickingLocation ? 'Use this location' : 'Create event here',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ).animate().moveY(begin: 100, end: 0, duration: 400.ms, curve: Curves.easeOutQuad).fadeIn(),
            ),

          // Empty / error hint
          if (selected == null && _pickedPlace == null && !showResults && !appState.loadingEvents && (appState.eventsError != null || shown.isEmpty))
            Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: GlassContainer(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(appState.eventsError != null ? LucideIcons.wifiOff : LucideIcons.mapPin,
                        color: AppTheme.primary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        appState.eventsError != null
                            ? '${appState.eventsError}. Tap refresh to retry.'
                            : _searchQuery.isNotEmpty
                                ? 'No events match "$_searchQuery". Try a place name to move the map.'
                                : 'No events nearby yet. Long-press the map to create one!',
                        style: TextStyle(color: isDark ? Colors.white : Colors.black),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          
          // Event Preview Card
          if (selected != null)
            Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: _buildEventCard(selected).animate().moveY(begin: 100, end: 0, duration: 400.ms, curve: Curves.easeOutQuad).fadeIn(),
            ),
        ],
      ),
      bottomNavigationBar: const BottomNav(),
    );
  }

  Widget _resultTile(bool isDark,
      {required IconData icon, required Color color, required String title, required String subtitle, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontWeight: FontWeight.w600, color: isDark ? Colors.white : Colors.black)),
                  if (subtitle.isNotEmpty)
                    Text(subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 12, color: isDark ? Colors.white54 : Colors.black54)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEventCard(JoinMeEvent event) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final categoryColor = AppTheme.colorsFor(event.category);
    
    return GlassContainer(
      backgroundColor: isDark 
          ? categoryColor.primary.withOpacity(0.1) 
          : categoryColor.primary.withOpacity(0.05),
      borderColor: categoryColor.primary.withOpacity(0.3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: categoryColor.primary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        event.category.toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      event.title,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(LucideIcons.mapPin, size: 14, color: categoryColor.primary),
                        const SizedBox(width: 4),
                        Text(
                          event.location.name,
                          style: TextStyle(
                            fontSize: 14,
                            color: isDark ? Colors.white70 : Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Avatar(name: event.host.name, url: event.host.avatarUrl, size: 48),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Icon(LucideIcons.users, size: 16, color: categoryColor.primary),
              const SizedBox(width: 4),
              Text('${event.participants} going'),
              const SizedBox(width: 16),
              Icon(LucideIcons.clock, size: 16, color: categoryColor.primary),
              const SizedBox(width: 4),
              Text(_startLabel(event)),
              const SizedBox(width: 16),
              Icon(LucideIcons.star, size: 16, color: AppTheme.primary),
              const SizedBox(width: 4),
              Text(formatReputation(event.host.reputation)),
            ],
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: () {
              context.read<AppState>().navigateTo('event', eventId: event.id);
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: categoryColor.primary,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: categoryColor.primary.withOpacity(0.4),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Center(
                child: Text(
                  'View Details',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
