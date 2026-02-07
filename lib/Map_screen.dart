import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
final mapController = MapController();
class MapScreen extends StatelessWidget {
  const MapScreen({super.key});
  

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("JoinMe"),),
      body: FlutterMap(
        mapController: mapController,
        
        options: const MapOptions(
          initialCenter: LatLng(9.03, 38.74,), // Addis Ababa
          initialZoom: 13,
        ),
        children: [
          TileLayer(
            urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
            userAgentPackageName: 'com.example.app',
          ),
          MarkerLayer(
            markers: [
              Marker(
                point: const LatLng(9.03, 38.74,),
                width: 80,
                height: 80,
                child: const Icon(
                  Icons.location_on,
                  size: 40,
                  color: Colors.red,
                ),
              ),
            ],
          ),
        ],
      ),
    );
    
  }
}
