import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:joinme/src/Screens/NavText.dart';


final mapController = MapController();

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final TextEditingController _searchController = TextEditingController();

  Marker? userPin;
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
        width: 40,
        height: 40,
        child: const Icon(
          // Icons.location_pin,
          Icons.emoji_flags_sharp,
          size: 40,
          color: Colors.red,
        ),
      );
    });

    await _fetchPlaceName(point);

    if (!mounted) return;

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
      headers: {
        'User-Agent': 'JoinMe-App',
      },
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
              width: 40,
              height: 40,
              child: const Icon(
                Icons.emoji_flags_sharp,
                size: 40,
                color: Colors.red,
              ),
            );
          });
          return;
        }
      }
      // no results or invalid coordinates
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Location not found')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error searching location')),
      );
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
                initialCenter: LatLng(9.03, 38.74), // Addis Ababa
                initialZoom: 13,
                onLongPress: _onMapLongPress, // 👈 USER-TRIGGERED PIN
              ),
              children: [
                TileLayer(
                  urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
                  userAgentPackageName: 'com.example.joinme',
                ),
                if (userPin != null) MarkerLayer(markers: [userPin!]),
              ],
            ),
          ),
          // TopBar overlay
          Positioned(
            
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              
              child: Align(
                
                  child: TopBar(),
                
              ),
            ),
          ),
          // Search bar overlay (semi-transparent)
          Positioned(
            top: 60, // below the TopBar
            left: 0,
            right: 0,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Search location',
                          prefixIcon: const Icon(Icons.search),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12),
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
        ],
      ),
    );
  }
}
