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
    // Crucial: Remove listener to prevent memory leaks and crashes
    final provider = context.read<GeofenceProvider>();
    provider.removeListener(_onPositionUpdate);
    provider.removeListener(_onTawafRecoveryUpdate);
    provider.removeListener(_onGuidanceUpdate);
    provider.removeListener(_onTawafCompletionUpdate);
    super.dispose();
  }

  void _onTawafCompletionUpdate() {
    if (!mounted) return;
    final geofence = context.read<GeofenceProvider>();
    if (!geofence.isTawafCompleted) return;
    unawaited(context.read<RitualProgressController>().markTawafCompleted());
    unawaited(
      context.read<RecommendationController>().logCompletionOnce(
        ritualType: RitualType.tawaf,
        completedUnits: geofence.tawafLapCount,
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
          const PracticeInfoBanner(
            icon: Icons.tips_and_updates_outlined,
            title: 'Practice tip',
            message: 'Tap the map to manually pin the Kaabah.',
            backgroundColor: Color(0xFFF8FAFC),
            foregroundColor: Color(0xFF1D4ED8),
            borderColor: Color(0xFFDBEAFE),
          ),
          _buildStatusBanner(context, geofence),
          const RecommendationPanel(ritualType: RitualType.tawaf),
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
                      context.read<GeofenceProvider>().setManualKaabahPoint(
                        point.latitude,
                        point.longitude,
                      );
                    },
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.mish.my_umrah_guide',
                      keepBuffer:
                          3, // Fixes AbortError on web by buffering tiles
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
                            borderColor:
                                geofence.status == GeofenceStatus.inside
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
                            child: const Icon(
                              Icons.location_on,
                              color: Colors.black,
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
                  bottom: 16,
                  left: 16,
                  right: 16,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: MediaQuery.of(context).size.height * 0.3,
                    ),
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (geofence.kaabahPosition == null)
                            ElevatedButton.icon(
                              onPressed: () => context
                                  .read<GeofenceProvider>()
                                  .setKaabahPoint(),
                              icon: const Icon(Icons.location_on),
                              label: const Text('Set Kaabah Location Here'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primaryColor,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                  horizontal: 20,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          const SizedBox(height: 8),
                          _buildDevOverlay(context),
                        ],
                      ),
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

  Widget _buildStatusBanner(BuildContext context, GeofenceProvider geofence) {
    String message = "Please set the Kaabah location to begin.";
    Color bgColor = Colors.grey.shade100;
    Color textColor = Colors.grey.shade700;
    IconData icon = Icons.info_outline;

    if (geofence.kaabahPosition != null) {
      if (geofence.isTawafPaused) {
        message = "TAWAF PAUSED - RE-ENTER ZONE TO CONTINUE";
        bgColor = Colors.orange.shade50;
        textColor = Colors.orange.shade800;
        icon = Icons.pause_circle_filled;
      } else if (geofence.status == GeofenceStatus.inside) {
        message = "YOU ARE INSIDE THE TAWAF ZONE";
        bgColor = Theme.of(context).colorScheme.primary.withValues(alpha: 0.1);
        textColor = Theme.of(context).colorScheme.primary;
        icon = Icons.check_circle;
      } else if (geofence.miqatTriggered) {
        message = "MIQAT APPROACHING (PREPARE NIYYAH)";
        bgColor = Colors.blue.shade50;
        textColor = Colors.blue.shade700;
        icon = Icons.access_time_filled;
      } else {
        message = "OUTSIDE TAWAF ZONE!";
        bgColor = Colors.red.shade50;
        textColor = Colors.red.shade700;
        icon = Icons.warning_amber_rounded;
      }
    }
    return PracticeInfoBanner(
      icon: icon,
      title: message,
      message: geofence.kaabahPosition != null
          ? 'Zone updates will follow your current Tawaf state.'
          : 'Set the Kaabah location to begin.',
      backgroundColor: bgColor,
      foregroundColor: textColor,
      borderColor: Colors.grey.shade200,
    );
  }

  Widget _buildLapCounter(BuildContext context, GeofenceProvider geofence) {
    return PracticeSurfaceCard(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
      backgroundColor: Colors.white,
      borderRadius: BorderRadius.zero,
      boxShadow: const [],
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
    return PracticeSurfaceCard(
      padding: const EdgeInsets.all(8),
      backgroundColor: Colors.white.withValues(alpha: 0.92),
      borderRadius: PracticeUi.panelRadius,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'SIMULATION DEMO',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              TextButton(
                onPressed: () => context
                    .read<GeofenceProvider>()
                    .simulateStatus(GeofenceStatus.inside),
                child: const Text('Enter', style: TextStyle(fontSize: 12)),
              ),
              TextButton(
                onPressed: () => context
                    .read<GeofenceProvider>()
                    .simulateStatus(GeofenceStatus.outside),
                child: const Text('Exit', style: TextStyle(fontSize: 12)),
              ),
              TextButton(
                onPressed: () =>
                    context.read<GeofenceProvider>().incrementTawafLap(),
                child: const Text('Next', style: TextStyle(fontSize: 12)),
              ),
            ],
          ),
        ],
      ),
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
