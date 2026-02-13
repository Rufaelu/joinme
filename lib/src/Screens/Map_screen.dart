import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
final mapController = MapController();
class MapScreen extends StatelessWidget {
  const MapScreen({super.key});
  

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("JoinMe"),
      backgroundColor: const Color.fromARGB(0, 233, 185, 112,),),

      body: FlutterMap(
        mapController: mapController,
        
        options: const MapOptions(
          initialCenter: LatLng(9.03, 38.74,), // Addis Ababa
          initialZoom: 13,
        ),
        children: [
          TileLayer(
            urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
            userAgentPackageName: 'com.example.joinme',
          ),
         
        ],
      ),
    );
    
  }
}
