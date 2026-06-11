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
  SaiProvider? _saiProvider;

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
      _saiProvider = provider;
      provider.startTracking();

      // Auto-follow listener
      provider.addListener(_onPositionUpdate);
      provider.addListener(_onGuidanceUpdate);
      provider.addListener(_onSaiCompletionUpdate);
    });
  }

  @override
  void dispose() {
    final provider = _saiProvider;
    if (provider != null) {
      provider.removeListener(_onPositionUpdate);
      provider.removeListener(_onGuidanceUpdate);
      provider.removeListener(_onSaiCompletionUpdate);
    }
    super.dispose();
  }

  void _onSaiCompletionUpdate() {
    if (!mounted) return;
    final sai = context.read<SaiProvider>();
    if (sai.saiLapCount < 7) return;

    final startedAt = sai.sessionStartedAt;
    final completedAt = DateTime.now();
    const saiDistance = 3100.0;

    unawaited(
      context.read<RecommendationController>().logCompletionOnce(
        ritualType: RitualType.sai,
        completedUnits: sai.saiLapCount,
        startedAt: startedAt,
        completedAt: completedAt,
        actualDistanceMeters: saiDistance,
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
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      backgroundColor: PracticeUi.mutedSurface,
      body: Stack(
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
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
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
                      color: PracticeUi.green.withValues(alpha: 0.16),
                    ),
                  ],
                ),
              CircleLayer(
                circles: [
                  CircleMarker(
                    point: sai.nextTarget == HillTarget.marwa
                        ? marwaLatLng
                        : safaLatLng,
                    color: PracticeUi.green.withValues(alpha: 0.18),
                    borderStrokeWidth: 2,
                    borderColor: PracticeUi.forest.withValues(alpha: 0.42),
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
                        Icon(Icons.location_on, color: PracticeUi.forest),
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
                        Icon(Icons.location_on, color: PracticeUi.forest),
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
          Positioned(
            top: 12,
            left: 12,
            right: 76,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isGpsNull) ...[
                  const PracticeMapPill(
                    icon: Icons.location_searching,
                    label: 'GPS pending',
                    color: Color(0xFF9A3412),
                  ),
                  const SizedBox(height: 8),
                ],
                if (_pinMode != PinMode.none) ...[
                  PracticeMapPill(
                    icon: Icons.push_pin,
                    label:
                        'Tap map to pin ${_pinMode == PinMode.safa ? 'SAFA' : 'MARWA'}',
                    color: primaryColor,
                  ),
                  const SizedBox(height: 8),
                ],
                _buildTargetChip(context, sai),
                const SizedBox(height: 8),
                _buildCompactProgress(context, sai),
                const SizedBox(height: 8),
                const RecommendationSheetButton(ritualType: RitualType.sai),
              ],
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
              elevation: 4,
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
              child: SingleChildScrollView(child: _buildDevOverlay(context)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTargetChip(BuildContext context, SaiProvider sai) {
    String target = sai.nextTarget == HillTarget.marwa ? "MARWA" : "SAFA";
    return PracticeMapPill(
      icon: Icons.directions_walk,
      label: 'Next target: $target',
      color: PracticeUi.gold,
    );
  }

  Widget _buildCompactProgress(BuildContext context, SaiProvider sai) {
    return PracticeSurfaceCard(
      padding: const EdgeInsets.all(12),
      backgroundColor: Colors.white.withValues(alpha: 0.96),
      borderRadius: PracticeUi.panelRadius,
      borderColor: PracticeUi.line,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  "Sa'i Laps",
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
              PracticeStatusChip(
                label: sai.saiLapCount >= 7 ? 'Complete' : 'In progress',
                icon: sai.saiLapCount >= 7
                    ? Icons.check_circle_outline
                    : Icons.timelapse,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: List.generate(
              7,
              (index) => Expanded(
                child: Container(
                  height: 8,
                  margin: EdgeInsets.only(right: index == 6 ? 0 : 5),
                  decoration: BoxDecoration(
                    color: index < sai.saiLapCount
                        ? PracticeUi.forest
                        : const Color(0xFFE4DED2),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Lap ${sai.saiLapCount} of 7',
                style: TextStyle(color: Colors.grey.shade700),
              ),
              Text(
                sai.saiLapCount >= 7 ? 'Journey complete' : 'Stay rhythmic',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: PracticeUi.ink,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            sai.currentLapProgressLabel,
            style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(Icons.near_me, size: 14, color: Colors.grey.shade500),
              const SizedBox(width: 6),
              Text(
                'Jarak ke ${
                  sai.nextTarget == HillTarget.marwa ? "MARWA" : "SAFA"
                }: ${PracticeUi.formatDistance(sai.distanceToNextTarget)}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: PracticeUi.ink,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDevOverlay(BuildContext context) {
    return PracticeCommandBar(
      children: [
        PracticeCommandButton(
          icon: Icons.place_outlined,
          label: 'Pin Safa',
          onPressed: () => setState(() => _pinMode = PinMode.safa),
        ),
        PracticeCommandButton(
          icon: Icons.place_rounded,
          label: 'Pin Marwa',
          onPressed: () => setState(() => _pinMode = PinMode.marwa),
        ),
        PracticeCommandButton(
          icon: Icons.flag_rounded,
          label: 'Reach Target',
          isPrimary: true,
          onPressed: () => context.read<SaiProvider>().simulateReachHill(),
        ),
      ],
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
