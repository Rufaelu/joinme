import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

final mapController = MapController();

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("JoinMe"),
        backgroundColor: const Color.fromARGB(255, 233, 185, 112),
      ),
      body: FlutterMap(
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
    );
  }
}
