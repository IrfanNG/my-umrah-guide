import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../sai_provider.dart';

class SaiSimulatorView extends StatelessWidget {
  const SaiSimulatorView({super.key});

  @override
  Widget build(BuildContext context) {
    final sai = context.watch<SaiProvider>();
    final primaryColor = Theme.of(context).colorScheme.primary;

    // Mecca Hills Coordinates
    const safaCenter = LatLng(21.4221, 39.8272);
    const marwaCenter = LatLng(21.4248, 39.8267);
    const meccaCenter = LatLng(21.4235, 39.8269); // Midpoint for view

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sa\'i Simulation'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Target Status Banner
          _buildTargetBanner(context, sai),

          // Lap Counter
          _buildLapCounter(context, sai),

          // Map
          Expanded(
            child: Stack(
              children: [
                FlutterMap(
                  options: MapOptions(
                    initialCenter: meccaCenter,
                    initialZoom: 17.0,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.mish.my_umrah_guide',
                    ),
                    
                    // Radius Visual for Target
                    CircleLayer(
                      circles: [
                        CircleMarker(
                          point: sai.nextTarget == HillTarget.marwa ? marwaCenter : safaCenter,
                          color: primaryColor.withValues(alpha: 0.1),
                          borderStrokeWidth: 2,
                          borderColor: primaryColor.withValues(alpha: 0.5),
                          useRadiusInMeter: true,
                          radius: sai.radius,
                        ),
                      ],
                    ),

                    // Markers
                    MarkerLayer(
                      markers: [
                        const Marker(
                          point: safaCenter,
                          width: 40, height: 40,
                          child: Column(
                            children: [
                              Text('SAFA', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                              Icon(Icons.location_on, color: Colors.brown),
                            ],
                          ),
                        ),
                        const Marker(
                          point: marwaCenter,
                          width: 40, height: 40,
                          child: Column(
                            children: [
                              Text('MARWA', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                              Icon(Icons.location_on, color: Colors.brown),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                // Controls
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
              const Text(
                " / 7",
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
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
                onPressed: () {
                  context.read<SaiProvider>().initHillsForDemo();
                },
                child: const Text('Init Hills'),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: () {
                  context.read<SaiProvider>().simulateReachHill();
                },
                child: const Text('Reached Target'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
