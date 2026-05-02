import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../domain/ritual_recommendation.dart';
import '../guidance/ritual_guidance_sheet.dart';
import '../recommendation_controller.dart';
import '../sai_provider.dart';
import '../widgets/recommendation_panel.dart';
import '../widgets/practice_ui.dart';

class SaiSimulatorView extends StatefulWidget {
  const SaiSimulatorView({super.key});

  @override
  State<SaiSimulatorView> createState() => _SaiSimulatorViewState();
}

enum PinMode { none, safa, marwa }

class _SaiSimulatorViewState extends State<SaiSimulatorView>
    with TickerProviderStateMixin {
  final MapController _mapController = MapController();
  bool _isMapReady = false;
  bool _isGuidanceSheetVisible = false;
  PinMode _pinMode = PinMode.none;

  void _animatedMapMove(LatLng destLocation, double destZoom) {
    final latTween = Tween<double>(
      begin: _mapController.camera.center.latitude,
      end: destLocation.latitude,
    );
    final lngTween = Tween<double>(
      begin: _mapController.camera.center.longitude,
      end: destLocation.longitude,
    );
    final zoomTween = Tween<double>(
      begin: _mapController.camera.zoom,
      end: destZoom,
    );

    final controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    final animation = CurvedAnimation(
      parent: controller,
      curve: Curves.fastOutSlowIn,
    );

    controller.addListener(() {
      _mapController.move(
        LatLng(latTween.evaluate(animation), lngTween.evaluate(animation)),
        zoomTween.evaluate(animation),
      );
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
      final provider = context.read<SaiProvider>();
      provider.startTracking();

      // Auto-follow listener
      provider.addListener(_onPositionUpdate);
      provider.addListener(_onGuidanceUpdate);
      provider.addListener(_onSaiCompletionUpdate);
    });
  }

  @override
  void dispose() {
    // Prevent memory leaks
    final provider = context.read<SaiProvider>();
    provider.removeListener(_onPositionUpdate);
    provider.removeListener(_onGuidanceUpdate);
    provider.removeListener(_onSaiCompletionUpdate);
    super.dispose();
  }

  void _onSaiCompletionUpdate() {
    if (!mounted) return;
    final sai = context.read<SaiProvider>();
    unawaited(
      context.read<RecommendationController>().logCompletionOnce(
        ritualType: RitualType.sai,
        completedUnits: sai.saiLapCount,
      ),
    );
  }

  void _onPositionUpdate() {
    if (!mounted || !_isMapReady) return;

    final sai = context.read<SaiProvider>();
    if (sai.currentPosition != null) {
      final userLatLng = LatLng(
        sai.currentPosition!.latitude,
        sai.currentPosition!.longitude,
      );

      // Only move camera if moved more than 0.5m
      double dist = const Distance().as(
        LengthUnit.Meter,
        _mapController.camera.center,
        userLatLng,
      );

      if (dist > 0.5) {
        _animatedMapMove(userLatLng, _mapController.camera.zoom);
      }
    }
  }

  void _onGuidanceUpdate() {
    if (!mounted || _isGuidanceSheetVisible) return;

    final sai = context.read<SaiProvider>();
    if (sai.pendingGuidance == null) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _isGuidanceSheetVisible) return;
      final latest = context.read<SaiProvider>();
      if (latest.pendingGuidance == null) return;
      _showGuidanceSheet();
    });
  }

  @override
  Widget build(BuildContext context) {
    final sai = context.watch<SaiProvider>();
    final primaryColor = Theme.of(context).colorScheme.primary;

    final isGpsNull = sai.currentPosition == null;
    final userLatLng = isGpsNull
        ? const LatLng(21.4235, 39.8269)
        : LatLng(sai.currentPosition!.latitude, sai.currentPosition!.longitude);

    final safaLatLng = sai.safaPosition != null
        ? LatLng(sai.safaPosition!.latitude, sai.safaPosition!.longitude)
        : const LatLng(21.4221, 39.8272);

    final marwaLatLng = sai.marwaPosition != null
        ? LatLng(sai.marwaPosition!.latitude, sai.marwaPosition!.longitude)
        : const LatLng(21.4248, 39.8267);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sa\'i Simulation'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Column(
        children: [
          if (isGpsNull)
            const PracticeInfoBanner(
              icon: Icons.location_searching,
              title: 'GPS pending',
              message: 'Acquiring GPS signal...',
              backgroundColor: Color(0xFFFFF7ED),
              foregroundColor: Color(0xFF9A3412),
              borderColor: Color(0xFFFCD9B6),
            ),
          if (_pinMode != PinMode.none)
            PracticeInfoBanner(
              icon: Icons.push_pin,
              title: 'Pin mode active',
              message:
                  'Tap the map to pin ${_pinMode == PinMode.safa ? 'SAFA' : 'MARWA'}.',
              backgroundColor: primaryColor.withValues(alpha: 0.1),
              foregroundColor: primaryColor,
              borderColor: primaryColor.withValues(alpha: 0.18),
            ),
          _buildTargetBanner(context, sai),
          const RecommendationPanel(ritualType: RitualType.sai),
          _buildLapCounter(context, sai),
          _buildCurrentLapProgress(context, sai),
          Expanded(
            child: Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: userLatLng,
                    initialZoom: 17.0,
                    onTap: (tapPos, point) {
                      if (_pinMode == PinMode.safa) {
                        context.read<SaiProvider>().setManualSafaPoint(
                          point.latitude,
                          point.longitude,
                        );
                        setState(() => _pinMode = PinMode.none);
                      } else if (_pinMode == PinMode.marwa) {
                        context.read<SaiProvider>().setManualMarwaPoint(
                          point.latitude,
                          point.longitude,
                        );
                        setState(() => _pinMode = PinMode.none);
                      }
                    },
                    onMapReady: () {
                      setState(() {
                        _isMapReady = true;
                      });
                    },
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.mish.my_umrah_guide',
                      keepBuffer: 3, // Fixes AbortError on Web
                    ),
                    // Visual 100m Corridor representation
                    if (sai.safaPosition != null && sai.marwaPosition != null)
                      PolylineLayer(
                        polylines: [
                          Polyline(
                            points: [safaLatLng, marwaLatLng],
                            strokeWidth: 40.0, // Visual corridor width
                            color: primaryColor.withValues(alpha: 0.1),
                          ),
                        ],
                      ),
                    CircleLayer(
                      circles: [
                        CircleMarker(
                          point: sai.nextTarget == HillTarget.marwa
                              ? marwaLatLng
                              : safaLatLng,
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
                          width: 40,
                          height: 40,
                          child: const Column(
                            children: [
                              Text(
                                'SAFA',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Icon(Icons.location_on, color: Colors.brown),
                            ],
                          ),
                        ),
                        Marker(
                          point: marwaLatLng,
                          width: 40,
                          height: 40,
                          child: const Column(
                            children: [
                              Text(
                                'MARWA',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Icon(Icons.location_on, color: Colors.brown),
                            ],
                          ),
                        ),
                        if (!isGpsNull)
                          Marker(
                            point: userLatLng,
                            width: 40,
                            height: 40,
                            child: const Icon(
                              Icons.person_pin_circle,
                              color: Colors.blue,
                              size: 40,
                            ),
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
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
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
                        _animatedMapMove(userLatLng, 17.0);
                      }
                    },
                    backgroundColor: Colors.white,
                    child: Icon(Icons.my_location, color: primaryColor),
                  ),
                ),
                Positioned(
                  bottom: 16,
                  left: 16,
                  right: 16,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: MediaQuery.of(context).size.height * 0.3,
                    ),
                    child: SingleChildScrollView(
                      child: _buildDevOverlay(context),
                    ),
                  ),
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
    return PracticeInfoBanner(
      icon: Icons.directions_walk,
      title: 'Next target: $target',
      message: 'Move toward the next hill and keep the corridor rhythm steady.',
      backgroundColor: Theme.of(
        context,
      ).colorScheme.primary.withValues(alpha: 0.1),
      foregroundColor: PracticeUi.gold,
      borderColor: Colors.grey.shade200,
    );
  }

  Widget _buildLapCounter(BuildContext context, SaiProvider sai) {
    return PracticeSurfaceCard(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
      backgroundColor: Colors.white,
      borderRadius: BorderRadius.zero,
      boxShadow: const [],
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

  Widget _buildCurrentLapProgress(BuildContext context, SaiProvider sai) {
    return PracticeInfoBanner(
      icon: Icons.route_rounded,
      title: 'Current progress',
      message: sai.currentLapProgressLabel,
      backgroundColor: const Color(0xFFF9FAFB),
      foregroundColor: const Color(0xFF4B5563),
      borderColor: Colors.grey.shade100,
    );
  }

  Widget _buildDevOverlay(BuildContext context) {
    return PracticeSurfaceCard(
      padding: const EdgeInsets.all(8),
      backgroundColor: Colors.white.withValues(alpha: 0.92),
      borderRadius: PracticeUi.panelRadius,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'SA\'I SETTINGS & SIMULATION',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 4),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ActionChip(
                  label: const Text('Pin Safa', style: TextStyle(fontSize: 12)),
                  onPressed: () => setState(() => _pinMode = PinMode.safa),
                  backgroundColor: _pinMode == PinMode.safa
                      ? Colors.blue.shade100
                      : null,
                ),
                const SizedBox(width: 8),
                ActionChip(
                  label: const Text(
                    'Pin Marwa',
                    style: TextStyle(fontSize: 12),
                  ),
                  onPressed: () => setState(() => _pinMode = PinMode.marwa),
                  backgroundColor: _pinMode == PinMode.marwa
                      ? Colors.blue.shade100
                      : null,
                ),
                const SizedBox(width: 8),
                ActionChip(
                  label: const Text('Reach', style: TextStyle(fontSize: 12)),
                  onPressed: () =>
                      context.read<SaiProvider>().simulateReachHill(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showGuidanceSheet() async {
    final guidance = context.read<SaiProvider>().pendingGuidance;
    if (guidance == null) return;

    _isGuidanceSheetVisible = true;
    try {
      await showModalBottomSheet<void>(
        context: context,
        showDragHandle: false,
        isScrollControlled: true,
        backgroundColor: Colors.white,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        builder: (_) => RitualGuidanceSheet(guidance: guidance),
      );
    } finally {
      if (mounted) {
        context.read<SaiProvider>().consumeGuidance();
      }
      _isGuidanceSheetVisible = false;
    }
  }
}
