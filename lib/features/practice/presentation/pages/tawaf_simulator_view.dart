import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../domain/ritual_recommendation.dart';
import '../guidance/ritual_guidance_sheet.dart';
import '../geofence_provider.dart';
import '../recommendation_controller.dart';
import '../ritual_progress_controller.dart';
import '../widgets/recommendation_panel.dart';
import '../widgets/practice_ui.dart';

class TawafSimulatorView extends StatefulWidget {
  const TawafSimulatorView({super.key});

  @override
  State<TawafSimulatorView> createState() => _TawafSimulatorViewState();
}

class _TawafSimulatorViewState extends State<TawafSimulatorView>
    with TickerProviderStateMixin {
  final MapController _mapController = MapController();
  bool _isMapReady = false;
  bool _isTawafExitDialogVisible = false;
  bool _isGuidanceSheetVisible = false;
  GeofenceProvider? _geofenceProvider;

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
      final provider = context.read<GeofenceProvider>();
      _geofenceProvider = provider;
      unawaited(provider.loadTawafProgress());
      unawaited(provider.startTracking());

      // Auto-follow listener
      provider.addListener(_onPositionUpdate);
      provider.addListener(_onTawafRecoveryUpdate);
      provider.addListener(_onGuidanceUpdate);
      provider.addListener(_onTawafCompletionUpdate);
    });
  }

  @override
  void dispose() {
    final provider = _geofenceProvider;
    if (provider != null) {
      provider.removeListener(_onPositionUpdate);
      provider.removeListener(_onTawafRecoveryUpdate);
      provider.removeListener(_onGuidanceUpdate);
      provider.removeListener(_onTawafCompletionUpdate);
    }
    super.dispose();
  }

  void _onTawafCompletionUpdate() {
    if (!mounted) return;
    final geofence = context.read<GeofenceProvider>();
    if (!geofence.isTawafCompleted) return;
    unawaited(context.read<RitualProgressController>().markTawafCompleted());

    final startedAt = geofence.sessionStartedAt;
    final completedAt = DateTime.now();
    final rawRadius = geofence.distance > 0 ? geofence.distance : 64.0;
    final effectiveRadius = rawRadius.clamp(15.0, 75.0);
    final tawafDistance = 7 * 2 * 3.141592653589793 * effectiveRadius;

    unawaited(
      context.read<RecommendationController>().logCompletionOnce(
        ritualType: RitualType.tawaf,
        completedUnits: geofence.tawafLapCount,
        startedAt: startedAt,
        completedAt: completedAt,
        actualDistanceMeters: tawafDistance,
      ),
    );
  }

  void _onPositionUpdate() {
    if (!mounted || !_isMapReady) return;

    final geofence = context.read<GeofenceProvider>();
    if (geofence.currentPosition != null) {
      final userLatLng = LatLng(
        geofence.currentPosition!.latitude,
        geofence.currentPosition!.longitude,
      );

      // Only move camera if significant distance changed to avoid micro-jitter
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

  void _onTawafRecoveryUpdate() {
    if (!mounted || _isTawafExitDialogVisible) return;

    final geofence = context.read<GeofenceProvider>();
    if (!geofence.shouldShowTawafExitPrompt) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _isTawafExitDialogVisible) return;
      final latest = context.read<GeofenceProvider>();
      if (!latest.shouldShowTawafExitPrompt) return;
      _showTawafExitDialog();
    });
  }

  void _onGuidanceUpdate() {
    if (!mounted || _isGuidanceSheetVisible || _isTawafExitDialogVisible) {
      return;
    }

    final geofence = context.read<GeofenceProvider>();
    if (geofence.shouldShowTawafExitPrompt ||
        geofence.pendingGuidance == null) {
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _isGuidanceSheetVisible || _isTawafExitDialogVisible) {
        return;
      }
      final latest = context.read<GeofenceProvider>();
      if (latest.shouldShowTawafExitPrompt || latest.pendingGuidance == null) {
        return;
      }
      _showGuidanceSheet();
    });
  }

  @override
  Widget build(BuildContext context) {
    final geofence = context.watch<GeofenceProvider>();
    final primaryColor = Theme.of(context).colorScheme.primary;

    // Use dummy Mecca coords if GPS is null, but we track if it's actually null
    final isGpsNull = geofence.currentPosition == null;
    final userLatLng = isGpsNull
        ? const LatLng(21.4225, 39.8262)
        : LatLng(
            geofence.currentPosition!.latitude,
            geofence.currentPosition!.longitude,
          );

    final kaabahLatLng = geofence.kaabahPosition != null
        ? LatLng(
            geofence.kaabahPosition!.latitude,
            geofence.kaabahPosition!.longitude,
          )
        : const LatLng(21.4225, 39.8262);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tawaf Simulation'),
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
              initialZoom: 18.0,
              onMapReady: () {
                setState(() {
                  _isMapReady = true;
                });
              },
              onTap: (tapPos, point) {
                context.read<GeofenceProvider>().setManualKaabahPoint(
                  point.latitude,
                  point.longitude,
                );
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.mish.my_umrah_guide',
                keepBuffer: 3, // Fixes AbortError on web by buffering tiles
              ),
              if (geofence.kaabahPosition != null)
                CircleLayer(
                  circles: [
                    CircleMarker(
                      point: kaabahLatLng,
                      color: geofence.status == GeofenceStatus.inside
                          ? PracticeUi.green.withValues(alpha: 0.18)
                          : Colors.red.withValues(alpha: 0.14),
                      borderStrokeWidth: 2,
                      borderColor: geofence.status == GeofenceStatus.inside
                          ? PracticeUi.forest.withValues(alpha: 0.42)
                          : Colors.red.shade700.withValues(alpha: 0.48),
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
                      child: const Icon(
                        Icons.location_on,
                        color: PracticeUi.forest,
                        size: 40,
                      ),
                    ),
                  if (!isGpsNull) // Only show user pin if GPS is acquired
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
                _buildStatusChip(context, geofence),
                const SizedBox(height: 8),
                _buildCompactProgress(context, geofence),
                const SizedBox(height: 8),
                RecommendationSheetButton(
                  ritualType: RitualType.tawaf,
                  currentRadius: geofence.distance > 0 ? geofence.distance : null,
                ),
              ],
            ),
          ),
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
              child: SingleChildScrollView(
                child: _buildDevOverlay(
                  context,
                  geofence.kaabahPosition == null,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(BuildContext context, GeofenceProvider geofence) {
    String message = "Please set the Kaabah location to begin.";
    Color textColor = Colors.grey.shade700;
    IconData icon = Icons.info_outline;

    if (geofence.kaabahPosition != null) {
      if (geofence.isTawafPaused) {
        message = "Tawaf paused";
        textColor = Colors.orange.shade800;
        icon = Icons.pause_circle_filled;
      } else if (geofence.status == GeofenceStatus.inside) {
        message = "Inside Tawaf zone";
        textColor = Theme.of(context).colorScheme.primary;
        icon = Icons.check_circle;
      } else if (geofence.miqatTriggered) {
        message = "Miqat approaching";
        textColor = Colors.blue.shade700;
        icon = Icons.access_time_filled;
      } else {
        message = "Outside Tawaf zone";
        textColor = Colors.red.shade700;
        icon = Icons.warning_amber_rounded;
      }
    }

    return PracticeMapPill(icon: icon, label: message, color: textColor);
  }

  Widget _buildCompactProgress(
    BuildContext context,
    GeofenceProvider geofence,
  ) {
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
                  'Tawaf Rounds',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
              PracticeStatusChip(
                label: geofence.isTawafCompleted ? 'Complete' : 'In progress',
                icon: geofence.isTawafCompleted
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
                    color: index < geofence.tawafLapCount
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
              Row(
                children: [
                  Text(
                    'Round ${geofence.tawafLapCount} of 7',
                    style: TextStyle(color: Colors.grey.shade700),
                  ),
                  if (geofence.isAutoLapTracking) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: PracticeUi.forest.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.sync, size: 12, color: PracticeUi.forest),
                          SizedBox(width: 2),
                          Text(
                            'Auto',
                            style: TextStyle(
                              fontSize: 10,
                              color: PracticeUi.forest,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
              Text(
                geofence.isTawafCompleted ? 'Ready for Sa\'i' : 'Keep steady',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: PracticeUi.ink,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDevOverlay(BuildContext context, bool needsKaabahPin) {
    return PracticeCommandBar(
      children: [
        if (needsKaabahPin)
          PracticeCommandButton(
            icon: Icons.my_location,
            label: 'Set Kaabah Here',
            onPressed: () => context.read<GeofenceProvider>().setKaabahPoint(),
          ),
        PracticeCommandButton(
          icon: Icons.login_rounded,
          label: 'Enter',
          onPressed: () => context.read<GeofenceProvider>().simulateStatus(
            GeofenceStatus.inside,
          ),
        ),
        PracticeCommandButton(
          icon: Icons.logout_rounded,
          label: 'Exit',
          onPressed: () => context.read<GeofenceProvider>().simulateStatus(
            GeofenceStatus.outside,
          ),
        ),
        PracticeCommandButton(
          icon: Icons.skip_next_rounded,
          label: 'Next Round',
          isPrimary: true,
          onPressed: () => context.read<GeofenceProvider>().incrementTawafLap(),
        ),
      ],
    );
  }

  Future<void> _showTawafExitDialog() async {
    _isTawafExitDialogVisible = true;
    final geofence = context.read<GeofenceProvider>();

    try {
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) {
          return AlertDialog(
            title: const Text('Tawaf paused'),
            content: Text(
              'You left the Tawaf zone at ${geofence.tawafLapCount} / 7 rounds. '
              'Continue will keep your progress and resume counting once you re-enter the zone.',
            ),
            actions: [
              TextButton(
                onPressed: () async {
                  await context.read<GeofenceProvider>().endTawafForLater();
                  if (!dialogContext.mounted) return;
                  Navigator.of(dialogContext).pop();
                  if (!mounted) return;
                  Navigator.of(context).pop();
                },
                child: const Text('End'),
              ),
              FilledButton(
                onPressed: () async {
                  await context
                      .read<GeofenceProvider>()
                      .continueTawafAfterExit();
                  if (!dialogContext.mounted) return;
                  Navigator.of(dialogContext).pop();
                },
                child: const Text('Continue'),
              ),
            ],
          );
        },
      );
    } finally {
      _isTawafExitDialogVisible = false;
    }
  }

  Future<void> _showGuidanceSheet() async {
    final guidance = context.read<GeofenceProvider>().pendingGuidance;
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
        context.read<GeofenceProvider>().consumeGuidance();
      }
      _isGuidanceSheetVisible = false;
    }
  }
}
