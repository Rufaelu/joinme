import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_marker_popup/flutter_map_marker_popup.dart';
import 'package:glassmorphism/glassmorphism.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:joinme/src/Screens/NavText.dart';

final mapController = MapController();
final PopupController popupController = PopupController();


class MapScreen extends StatefulWidget {
  final bool isDark;
  const MapScreen({super.key, required this.isDark});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final TextEditingController _searchController = TextEditingController();

  Marker? userPin;
  List<Marker> markers = [];
  String? locationName;
  LatLng? pinnedPoint;

  /// Reverse geocode using OpenStreetMap Nominatim
  Future<void> _fetchPlaceName(LatLng point) async {
    final url =
        'https://nominatim.openstreetmap.org/reverse?format=jsonv2&lat=${point.latitude}&lon=${point.longitude}';

    final response = await http.get(
      Uri.parse(url),
      headers: {
        'User-Agent': 'JoinMe-App', // REQUIRED by Nominatim
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      setState(() {
        locationName =
            data['name'] ??
            data['address']?['cafe'] ??
            data['address']?['place'] ??
            data['address']?['restaurant'] ??
            data['address']?['amenity'] ??
            data['address']?['road'];
      });
    } else {
      setState(() => locationName = null);
    }
  }

  void _onMapLongPress(TapPosition tapPosition, LatLng point) async {
    setState(() {
      pinnedPoint = point;
      locationName = null;
      userPin = Marker(
        point: point,
        width: 60,
        height: 60,
        child: AnimatedScale(
          scale: 1.2,
          duration: const Duration(milliseconds: 400),
          curve: Curves.elasticOut,
          child: Image.asset('images/JoinMe.png', width: 48, height: 48),
        ),
      );
      markers = [userPin!];
    });
    await _fetchPlaceName(point);
    if (!mounted) return;
    popupController.showPopupsOnlyFor([userPin!]);
    _showPinInfo(context);
  }

  /// Perform a forward geocode search using OpenStreetMap Nominatim.
  Future<void> _searchLocation(String query) async {
    if (query.trim().isEmpty) return;

    // restrict search to Ethiopia using countrycodes=et (ISO 3166-1 alpha2)
    final url =
        'https://nominatim.openstreetmap.org/search?format=jsonv2&countrycodes=et&q=${Uri.encodeComponent(query)}&limit=1';

    final response = await http.get(
      Uri.parse(url),
      headers: {'User-Agent': 'JoinMe-App'},
    );

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      if (data.isNotEmpty) {
        final place = data.first;
        final lat = double.tryParse(place['lat'].toString());
        final lon = double.tryParse(place['lon'].toString());

        if (lat != null && lon != null) {
          final point = LatLng(lat, lon);

          mapController.move(point, 15);
          setState(() {
            pinnedPoint = point;
            locationName = place['display_name'];
            userPin = Marker(
              point: point,
              width: 60,
              height: 60,
              child: AnimatedScale(
                scale: 1.2,
                duration: const Duration(milliseconds: 400),
                curve: Curves.elasticOut,
                child: Image.asset('images/JoinMe.png', width: 48, height: 48),
              ),
            );
            markers = [userPin!];
          });
          return;
        }
      }
      // no results or invalid coordinates
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Location not found')));
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Error searching location')));
    }
  }

  void _showPinInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: SingleChildScrollView(
              child: Form(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Pin Location Details",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      "Latitude: ${pinnedPoint!.latitude.toStringAsFixed(6)}",
                    ),
                    Text(
                      "Longitude: ${pinnedPoint!.longitude.toStringAsFixed(6)}",
                    ),
                    if (locationName != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.storefront, color: Colors.orange),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                "Registered as: $locationName",
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    TextFormField(
                      decoration: const InputDecoration(
                        labelText: 'Location Name / Title',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text("Cancel"),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color.fromARGB(
                              255,
                              233,
                              185,
                              112,
                            ),
                            foregroundColor: Colors.black,
                          ),
                          onPressed: () {
                            // TODO: Handle form submission with coordinates
                            Navigator.of(context).pop();
                          },
                          child: const Text("Save Location"),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Use theme mode for map tiles
    final isDark = widget.isDark;
    return Scaffold(
      backgroundColor: Colors.transparent,
      drawerScrimColor: Colors.transparent,
      body: Stack(
        children: [
          // Map at the bottom
          Positioned.fill(
            child: FlutterMap(
              mapController: mapController,
              options: MapOptions(
                initialCenter: LatLng(9.03, 38.74),
                initialZoom: 13,
                onLongPress: _onMapLongPress,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.joinme',
                  // Always use default OpenStreetMap tiles for all themes
                ),
                if (markers.isNotEmpty)
                  PopupMarkerLayerWidget(
                    options: PopupMarkerLayerOptions(
                      markers: markers,
                      popupController: popupController,
                      popupDisplayOptions: PopupDisplayOptions(
                        builder: (context, marker) => Card(
                          color: Colors.white.withOpacity(0.95),
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  locationName ?? 'Pinned Location',
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                if (pinnedPoint != null)
                                  Text(
                                    'Lat: ${pinnedPoint!.latitude.toStringAsFixed(5)}, Lng: ${pinnedPoint!.longitude.toStringAsFixed(5)}',
                                    style: const TextStyle(fontSize: 12),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          // TopBar overlay
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(child: Align(child: TopBar())),
          ),
          // Search bar overlay (glassmorphism)
          Positioned(
            top: 60,
            left: 0,
            right: 0,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: GlassmorphicContainer(
                width: double.infinity,
                height: 56,
                borderRadius: 16,
                blur: 16,
                alignment: Alignment.center,
                border: 1,
                linearGradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withOpacity(0.25),
                    Colors.white.withOpacity(0.05),
                  ],
                  stops: const [0.1, 1],
                ),
                borderGradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withOpacity(0.5),
                    Colors.white.withOpacity(0.1),
                  ],
                ),
                child: Row(
                  children: [
                    // Event search field
                    Expanded(
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: 'Search event',
                          prefixIcon: const Icon(Icons.event),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                          ),
                        ),
                        style: const TextStyle(color: Colors.black),
                        // TODO: Implement event search logic
                        onSubmitted: (value) {
                          // Placeholder for event search
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Location search field
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Search location',
                          prefixIcon: const Icon(Icons.search),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                          ),
                        ),
                        textInputAction: TextInputAction.search,
                        onSubmitted: _searchLocation,
                        style: const TextStyle(color: Colors.black),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black.withOpacity(0.5),
                        foregroundColor: Colors.white,
                        elevation: 0,
                      ),
                      onPressed: () => _searchLocation(_searchController.text),
                      child: const Text('Go'),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Map controls (zoom in/out, recenter)
          Positioned(
            bottom: 32,
            right: 16,
            child: Column(
              children: [
                FloatingActionButton(
                  heroTag: 'zoomIn',
                  mini: true,
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                  onPressed: () => mapController.move(
                    mapController.camera.center,
                    mapController.camera.zoom + 1,
                  ),
                  child: const Icon(Icons.add),
                ),
                const SizedBox(height: 8),
                FloatingActionButton(
                  heroTag: 'zoomOut',
                  mini: true,
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                  onPressed: () => mapController.move(
                    mapController.camera.center,
                    mapController.camera.zoom - 1,
                  ),
                  child: const Icon(Icons.remove),
                ),
                const SizedBox(height: 8),
                FloatingActionButton(
                  heroTag: 'recenter',
                  mini: true,
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                  onPressed: () => mapController.move(LatLng(9.03, 38.74), 13),
                  child: const Icon(Icons.my_location),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
