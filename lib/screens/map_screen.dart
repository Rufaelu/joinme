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
import '../data/mock_data.dart';
import '../widgets/glass_container.dart';
import '../widgets/bottom_nav.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({Key? key}) : super(key: key);

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  JoinMeEvent? _selectedEvent;
  final String _searchQuery = '';
  
  // Addis Ababa coordinates as default
  LatLng _currentLocation = const LatLng(9.0300, 38.7400);
  bool _isLoadingLocation = true;
  
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
      final events = context.read<AppState>().events;
      if (events.isNotEmpty && _selectedEvent == null) {
        setState(() {
          _selectedEvent = events[0];
        });
      }
    });
    _determinePosition();
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
                color: isDark ? const Color(0xFF1a363d) : Colors.white,
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
                            color: Colors.blue[500]!.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(LucideIcons.mapPin, color: Colors.blue[400]),
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
                          color: isLoading ? (isDark ? Colors.white10 : Colors.black12) : Colors.yellow[500],
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
    
    return Scaffold(
      body: Stack(
        children: [
          // FlutterMap Background
          if (!_isLoadingLocation)
            FlutterMap(
              options: MapOptions(
                initialCenter: _currentLocation,
                initialZoom: 13.0,
                onTap: (tapPosition, point) {
                  setState(() {
                    _selectedEvent = null;
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
                markers: context.watch<AppState>().events.map((event) {
                  final isSelected = _selectedEvent?.id == event.id;
                  final categoryColor = AppTheme.categoryColors[event.category]!;
                  
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
                    color: isDark ? Colors.yellow[400] : Colors.blue[500],
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
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                borderRadius: 30,
                child: Text(
                  'JoinMe',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
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
                      decoration: InputDecoration(
                        hintText: 'Search events...',
                        border: InputBorder.none,
                        hintStyle: TextStyle(color: isDark ? Colors.white54 : Colors.black54),
                      ),
                      style: TextStyle(color: isDark ? Colors.white : Colors.black),
                    ),
                  ),
                  Icon(LucideIcons.zap, color: isDark ? Colors.white54 : Colors.black54),
                ],
              ),
            ),
          ),
          
          // Event Preview Card
          if (_selectedEvent != null)
            Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: _buildEventCard(_selectedEvent!).animate().moveY(begin: 100, end: 0, duration: 400.ms, curve: Curves.easeOutQuad).fadeIn(),
            ),
        ],
      ),
      bottomNavigationBar: const BottomNav(),
    );
  }

  Widget _buildEventCard(JoinMeEvent event) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final categoryColor = AppTheme.categoryColors[event.category]!;
    
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
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [categoryColor.primary, categoryColor.secondary],
                  ),
                ),
                child: Center(
                  child: Text(
                    event.host.avatar,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Icon(LucideIcons.users, size: 16, color: categoryColor.primary),
              const SizedBox(width: 4),
              Text('${event.participants}/${event.maxParticipants}'),
              const SizedBox(width: 16),
              Icon(LucideIcons.clock, size: 16, color: categoryColor.primary),
              const SizedBox(width: 4),
              Text('${event.timeRemaining}m'),
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
