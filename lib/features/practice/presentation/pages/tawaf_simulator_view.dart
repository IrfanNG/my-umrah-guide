import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../geofence_provider.dart';

class TawafSimulatorView extends StatefulWidget {
  const TawafSimulatorView({super.key});

  @override
  State<TawafSimulatorView> createState() => _TawafSimulatorViewState();
}

class _TawafSimulatorViewState extends State<TawafSimulatorView> with TickerProviderStateMixin {
  final MapController _mapController = MapController();
  bool _isMapReady = false;

  void _animatedMapMove(LatLng destLocation, double destZoom) {
    final latTween = Tween<double>(
        begin: _mapController.camera.center.latitude, end: destLocation.latitude);
    final lngTween = Tween<double>(
        begin: _mapController.camera.center.longitude, end: destLocation.longitude);
    final zoomTween = Tween<double>(begin: _mapController.camera.zoom, end: destZoom);

    final controller = AnimationController(
        duration: const Duration(milliseconds: 500), vsync: this);
    final animation = CurvedAnimation(parent: controller, curve: Curves.fastOutSlowIn);

    controller.addListener(() {
      _mapController.move(
          LatLng(latTween.evaluate(animation), lngTween.evaluate(animation)),
          zoomTween.evaluate(animation));
    });

    animation.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        controller.dispose();
      } else if (status == AnimationStatus.dismissed) {
        controller.dispose();
      }
    });

    controller.forward();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<GeofenceProvider>().startTracking();
    });
  }

  @override
  Widget build(BuildContext context) {
    final geofence = context.watch<GeofenceProvider>();
    final primaryColor = Theme.of(context).colorScheme.primary;

    final userLatLng = geofence.currentPosition != null
        ? LatLng(geofence.currentPosition!.latitude, geofence.currentPosition!.longitude)
        : const LatLng(21.4225, 39.8262);
    
    final kaabahLatLng = geofence.kaabahPosition != null
        ? LatLng(geofence.kaabahPosition!.latitude, geofence.kaabahPosition!.longitude)
        : const LatLng(21.4225, 39.8262);

    // Smooth follow user if GPS is active
    if (geofence.currentPosition != null && _isMapReady) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        // Only animate if distance is significant to avoid micro-jitter
        double dist = const Distance().as(LengthUnit.Meter, _mapController.camera.center, userLatLng);
        if (dist > 1.0) {
           _animatedMapMove(userLatLng, _mapController.camera.zoom);
        }
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tawaf Simulation'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Column(
        children: [
          if (geofence.currentPosition == null)
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
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(8),
            color: Colors.blue.shade50,
            child: const Center(
              child: Text(
                "Tip: Tap on map to manually pin the Kaabah",
                style: TextStyle(fontSize: 11, color: Colors.blue),
              ),
            ),
          ),
          _buildStatusBanner(context, geofence),
          _buildLapCounter(context, geofence),
          Expanded(
            child: Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: userLatLng,
                    initialZoom: 18.0,
                    onMapReady: () {
                      setState(() {
                        _isMapReady = true;
                      });
                    },
                    onTap: (tapPos, point) {
                      context.read<GeofenceProvider>().setManualKaabahPoint(point.latitude, point.longitude);
                    },
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.mish.my_umrah_guide',
                    ),
                    if (geofence.kaabahPosition != null)
                      CircleLayer(
                        circles: [
                          CircleMarker(
                            point: kaabahLatLng, 
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
                    MarkerLayer(
                      markers: [
                        if (geofence.kaabahPosition != null)
                          Marker(
                            point: kaabahLatLng,
                            width: 40,
                            height: 40,
                            child: const Icon(Icons.location_on, color: Colors.black, size: 40),
                          ),
                        Marker(
                          point: userLatLng,
                          width: 40,
                          height: 40,
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
                      geofence.currentPosition != null 
                        ? "${geofence.currentPosition!.latitude.toStringAsFixed(4)}, ${geofence.currentPosition!.longitude.toStringAsFixed(4)}"
                        : "No GPS Data",
                      style: const TextStyle(color: Colors.white, fontSize: 10),
                    ),
                  ),
                ),
                // Locate Me Button
                Positioned(
                  top: 16,
                  right: 16,
                  child: FloatingActionButton.small(
                    onPressed: () {
                      if (_isMapReady) {
                        _animatedMapMove(userLatLng, 18.0);
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

  Widget _buildLapCounter(BuildContext context, GeofenceProvider geofence) {
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
            "Tawaf Rounds",
            style: TextStyle(fontWeight: FontWeight.w600, color: Colors.grey),
          ),
          Row(
            children: [
              Text(
                "${geofence.tawafLapCount}",
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
              const SizedBox(height: 30, child: VerticalDivider()),
              TextButton(
                onPressed: () => context.read<GeofenceProvider>().simulateStatus(GeofenceStatus.outside),
                child: const Text('Exit Zone'),
              ),
              const SizedBox(height: 30, child: VerticalDivider()),
              TextButton(
                onPressed: () => context.read<GeofenceProvider>().incrementTawafLap(),
                child: const Text('Next Round'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
