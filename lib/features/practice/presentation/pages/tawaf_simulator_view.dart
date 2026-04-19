import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../geofence_provider.dart';

class TawafSimulatorView extends StatelessWidget {
  const TawafSimulatorView({super.key});

  @override
  Widget build(BuildContext context) {
    final geofence = context.watch<GeofenceProvider>();
    final primaryColor = Theme.of(context).colorScheme.primary;

    // Mecca Coordinates
    const meccaCenter = LatLng(21.4225, 39.8262);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tawaf Simulation'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Status Banner (Maya's Design)
          _buildStatusBanner(context, geofence),

          // Real Map (OpenStreetMap)
          Expanded(
            child: Stack(
              children: [
                FlutterMap(
                  options: MapOptions(
                    initialCenter: meccaCenter,
                    initialZoom: 18.0,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.mish.my_umrah_guide',
                    ),
                    
                    // Radius Visual (Aura)
                    if (geofence.kaabahPosition != null)
                      CircleLayer(
                        circles: [
                          CircleMarker(
                            point: meccaCenter, // In real demo, this matches kaabahPosition
                            color: geofence.status == GeofenceStatus.inside
                                ? primaryColor.withValues(alpha: 0.1)
                                : Colors.transparent,
                            borderStrokeWidth: 2,
                            borderColor: geofence.status == GeofenceStatus.inside
                                ? primaryColor.withValues(alpha: 0.5)
                                : Colors.grey.withValues(alpha: 0.4),
                            useRadiusInMeter: true,
                            radius: geofence.radius,
                          ),
                        ],
                      ),

                    // Marker Layer (User & Kaabah)
                    MarkerLayer(
                      markers: [
                        // Kaabah Pin
                        const Marker(
                          point: meccaCenter,
                          width: 40,
                          height: 40,
                          child: Icon(Icons.location_on, color: Colors.black, size: 40),
                        ),
                        // User Location Marker
                        if (geofence.status == GeofenceStatus.inside)
                          const Marker(
                            point: meccaCenter, // In simulation, we center user
                            width: 20,
                            height: 20,
                            child: Icon(Icons.person_pin_circle, color: Colors.blue, size: 30),
                          ),
                      ],
                    ),
                  ],
                ),

                // Interaction Controls
                Positioned(
                  bottom: 24,
                  left: 24,
                  right: 24,
                  child: Column(
                    children: [
                      if (geofence.kaabahPosition == null)
                        ElevatedButton.icon(
                          onPressed: () => context.read<GeofenceProvider>().setKaabahPoint(),
                          icon: const Icon(Icons.location_on),
                          label: const Text('Set Kaabah Location Here'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      
                      const SizedBox(height: 16),
                      // Dev Simulation Overlay
                      _buildDevOverlay(context),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBanner(BuildContext context, GeofenceProvider geofence) {
    String message = "Please set the Kaabah location to begin.";
    Color bgColor = Colors.grey.shade100;
    Color textColor = Colors.grey.shade700;
    IconData icon = Icons.info_outline;

    if (geofence.kaabahPosition != null) {
      if (geofence.status == GeofenceStatus.inside) {
        message = "YOU ARE INSIDE THE KAABAH RADIUS";
        bgColor = Theme.of(context).colorScheme.primary.withValues(alpha: 0.1);
        textColor = Theme.of(context).colorScheme.primary;
        icon = Icons.check_circle;
      } else {
        message = "OUTSIDE RADIUS ALERT!";
        bgColor = Colors.red.shade50;
        textColor = Colors.red.shade700;
        icon = Icons.warning_amber_rounded;
      }
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        color: bgColor,
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: textColor),
          const SizedBox(width: 12),
          Text(
            message,
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
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
            'SIMULATION DEMO',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              TextButton(
                onPressed: () => context.read<GeofenceProvider>().simulateStatus(GeofenceStatus.inside),
                child: const Text('Enter Zone'),
              ),
              const SizedBox(
                height: 30,
                child: VerticalDivider(),
              ),
              TextButton(
                onPressed: () => context.read<GeofenceProvider>().simulateStatus(GeofenceStatus.outside),
                child: const Text('Exit Zone'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
