import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../app_state.dart';
import '../models.dart';
import 'helpers.dart';
import 'landmark_details.dart';


class MapScreen extends StatelessWidget {
  const MapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();


    final plottable = state.landmarks.where((l) => l.isPlottable).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Map'),
        actions: [
          IconButton(
            onPressed: state.refresh,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Column(
        children: [
          if (!state.online)
            Container(
              width: double.infinity,
              color: Colors.orange.shade100,
              padding: const EdgeInsets.all(8),
              child: const Text('Offline - showing cached landmarks'),
            ),
          if (state.focused != null)
            Container(
              width: double.infinity,
              color: Colors.teal.shade100,
              padding: const EdgeInsets.all(8),
              child: Text('Showing: ${state.focused!.title}'),
            ),
          Expanded(
            child: FlutterMap(
              mapController: state.mapController,
              options: MapOptions(
                initialCenter: LatLng(23.6850, 90.3563),
                initialZoom: 6.5,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.geotaggedlandmark',
                ),
                MarkerLayer(
                  markers: [
                    for (final Landmark l in plottable)
                      Marker(
                        point: LatLng(l.lat, l.lon),
                        width: 56,
                        height: 56,
                        child: GestureDetector(
                          onTap: () => showLandmarkDetails(context, l),
                          child: Icon(
                            Icons.location_on,

                            size: state.focused?.id == l.id ? 52 : 32,
                            color: scoreColor(
                              l.score,
                              state.lowestScore,
                              state.highestScore,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
