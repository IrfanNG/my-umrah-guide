import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../sai_provider.dart';

class SaiSimulatorView extends StatefulWidget {
  const SaiSimulatorView({super.key});

  @override
  State<SaiSimulatorView> createState() => _SaiSimulatorViewState();
}

class _SaiSimulatorViewState extends State<SaiSimulatorView> {
  final MapController _mapController = MapController();
  bool _isMapReady = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SaiProvider>().startTracking();
    });
  }

  @override
  Widget build(BuildContext context) {
    final sai = context.watch<SaiProvider>();
    final primaryColor = Theme.of(context).colorScheme.primary;

    final userLatLng = sai.currentPosition != null
        ? LatLng(sai.currentPosition!.latitude, sai.currentPosition!.longitude)
        : const LatLng(21.4235, 39.8269);

    final safaLatLng = sai.safaPosition != null
        ? LatLng(sai.safaPosition!.latitude, sai.safaPosition!.longitude)
        : const LatLng(21.4221, 39.8272);
    
    final marwaLatLng = sai.marwaPosition != null
        ? LatLng(sai.marwaPosition!.latitude, sai.marwaPosition!.longitude)
        : const LatLng(21.4248, 39.8267);

    // Auto-follow logic
    if (sai.currentPosition != null && _isMapReady) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _mapController.move(userLatLng, _mapController.camera.zoom);
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sa\'i Simulation'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Column(
        children: [
          if (sai.currentPosition == null)
            Container(
              padding: const EdgeInsets.all(8),
              color: Colors.orange.shade100,
              child: const Row(
                children: [
                  Icon(Icons.gps_fixed, size: 16),
                  SizedBox(width: 8),
                  Text("Waiting for GPS signal...", style: TextStyle(fontSize: 12)),
                ],
              ),
            ),
          _buildTargetBanner(context, sai),
          _buildLapCounter(context, sai),
          Expanded(
            child: Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: userLatLng,
                    initialZoom: 17.0,
                    onMapReady: () {
                      setState(() {
                        _isMapReady = true;
                      });
                    },
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.mish.my_umrah_guide',
                    ),
                    CircleLayer(
                      circles: [
                        CircleMarker(
                          point: sai.nextTarget == HillTarget.marwa ? marwaLatLng : safaLatLng,
                          color: primaryColor.withValues(alpha: 0.1),
                          borderStrokeWidth: 2,
                          borderColor: primaryColor.withValues(alpha: 0.5),
                          useRadiusInMeter: true,
                          radius: sai.radius,
                        ),
                      ],
                    ),
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: safaLatLng,
                          width: 40, height: 40,
                          child: const Column(
                            children: [
                              Text('SAFA', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                              Icon(Icons.location_on, color: Colors.brown),
                            ],
                          ),
                        ),
                        Marker(
                          point: marwaLatLng,
                          width: 40, height: 40,
                          child: const Column(
                            children: [
                              Text('MARWA', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                              Icon(Icons.location_on, color: Colors.brown),
                            ],
                          ),
                        ),
                        Marker(
                          point: userLatLng,
                          width: 40, height: 40,
                          child: const Icon(Icons.person_pin_circle, color: Colors.blue, size: 40),
                        ),
                      ],
                    ),
                  ],
                ),
                // Debug LatLng Overlay
                Positioned(
                  top: 70,
                  right: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      sai.currentPosition != null 
                        ? "${sai.currentPosition!.latitude.toStringAsFixed(4)}, ${sai.currentPosition!.longitude.toStringAsFixed(4)}"
                        : "No GPS Data",
                      style: const TextStyle(color: Colors.white, fontSize: 10),
                    ),
                  ),
                ),
                Positioned(
                  top: 16,
                  right: 16,
                  child: FloatingActionButton.small(
                    onPressed: () {
                      if (_isMapReady) {
                        _mapController.move(userLatLng, 17.0);
                      }
                    },
                    backgroundColor: Colors.white,
                    child: Icon(Icons.my_location, color: primaryColor),
                  ),
                ),
                Positioned(
                  bottom: 24,
                  left: 24,
                  right: 24,
                  child: _buildDevOverlay(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTargetBanner(BuildContext context, SaiProvider sai) {
    String target = sai.nextTarget == HillTarget.marwa ? "MARWA" : "SAFA";
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.directions_walk, color: Color(0xFFD4AF37)),
          const SizedBox(width: 12),
          Text(
            "NEXT TARGET: $target",
            style: const TextStyle(
              color: Color(0xFFD4AF37),
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLapCounter(BuildContext context, SaiProvider sai) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            "Sa'i Laps",
            style: TextStyle(fontWeight: FontWeight.w600, color: Colors.grey),
          ),
          Row(
            children: [
              Text(
                "${sai.saiLapCount}",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const Text(" / 7", style: TextStyle(fontSize: 16, color: Colors.grey)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDevOverlay(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        children: [
          const Text(
            'SA\'I SIMULATION',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: () => context.read<SaiProvider>().initHillsLocally(),
                child: const Text('Set Hills Locally'),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: () => context.read<SaiProvider>().simulateReachHill(),
                child: const Text('Reached Target'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
