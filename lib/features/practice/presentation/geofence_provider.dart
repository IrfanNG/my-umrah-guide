import 'dart:async';
import 'dart:math' show asin, cos, sqrt, atan2;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/services/notification_service.dart';
import 'guidance/ritual_guidance.dart';
import 'privacy_consent_controller.dart';

enum GeofenceStatus { initial, inside, outside }

class GeofenceProvider with ChangeNotifier {
  static const String _tawafLapCountKey = 'tawaf_lap_count';
  static const String _tawafIsPausedKey = 'tawaf_is_paused';
  static const String _tawafIsCompletedKey = 'tawaf_is_completed';

  Position? _currentPosition;
  Position? _kaabahPosition;
  GeofenceStatus _status = GeofenceStatus.initial;
  bool _miqatTriggered = false; // New: Miqat status

  final double _radius = 75.0; // Tawaf radius per PDF
  final double _miqatRadius = 150.0; // Miqat radius per PDF Table 5

  double _distance = 0.0;
  int _tawafLapCount = 0;
  bool _isTawafPaused = false;
  bool _isTawafCompleted = false;
  bool _tawafExitPromptPending = false;
  RitualGuidance? _pendingGuidance;
  final Set<String> _shownGuidanceIds = <String>{};
  Future<void> _tawafPersistenceQueue = Future<void>.value();
  StreamSubscription<Position>? _positionStream;

  // Auto-lap tracking
  double? _tawafZoneEntryAngle;
  double? _previousTawafAngle;
  bool _hasCompletedFullCircleInZone = false;

  Position? get currentPosition => _currentPosition;
  Position? get kaabahPosition => _kaabahPosition;
  GeofenceStatus get status => _status;
  bool get miqatTriggered => _miqatTriggered; // Getter for Miqat
  double get radius => _radius;
  double get distance => _distance;
  int get tawafLapCount => _tawafLapCount;
  bool get isTawafPaused => _isTawafPaused;
  bool get isTawafCompleted => _isTawafCompleted;
  bool get hasSavedTawafProgress => _tawafLapCount > 0 && _tawafLapCount < 7;
  bool get shouldShowTawafExitPrompt => _tawafExitPromptPending;
  RitualGuidance? get pendingGuidance => _pendingGuidance;
  bool get isAutoLapTracking =>
      _tawafZoneEntryAngle != null && status == GeofenceStatus.inside;

  // Set the reference point (Kaabah) to current user location
  Future<void> setKaabahPoint() async {
    if (!await PrivacyConsentController.hasAcceptedLocationConsent()) return;

    // Optimization: Use cached stream position for instant feedback
    if (_currentPosition != null) {
      _kaabahPosition = _currentPosition;
      _applyGeofenceStatus(GeofenceStatus.inside);
      notifyListeners();
      return;
    }

    // Fallback if stream hasn't locked yet
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return;
      }

      // Try getting position but limit wait time
      Position pos = await Geolocator.getCurrentPosition().timeout(
        const Duration(seconds: 3),
      );
      updatePosition(pos, force: true);
      _kaabahPosition = pos;
      _applyGeofenceStatus(GeofenceStatus.inside);
      notifyListeners();
    } catch (e) {
      debugPrint("GPS Error/Timeout: $e. Falling back to dummy location.");
      _setDummyKaabah();
    }
  }

  void setManualKaabahPoint(double lat, double lng) {
    _kaabahPosition = Position(
      latitude: lat,
      longitude: lng,
      timestamp: DateTime.now(),
      accuracy: 0,
      altitude: 0,
      heading: 0,
      speed: 0,
      speedAccuracy: 0,
      altitudeAccuracy: 0,
      headingAccuracy: 0,
    );
    _applyGeofenceStatus(GeofenceStatus.inside);
    notifyListeners();
  }

  void _setDummyKaabah() {
    _kaabahPosition = Position(
      latitude: 21.4225,
      longitude: 39.8262,
      timestamp: DateTime.now(),
      accuracy: 0,
      altitude: 0,
      heading: 0,
      speed: 0,
      speedAccuracy: 0,
      altitudeAccuracy: 0,
      headingAccuracy: 0,
    );
    _applyGeofenceStatus(GeofenceStatus.inside);
    notifyListeners();
  }

  void updatePosition(Position position, {bool force = false}) {
    // Throttle: Only update if moved more than 0.5 meters to prevent jitter loops
    if (!force && _currentPosition != null) {
      double moveDist = _calculateDistance(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
        position.latitude,
        position.longitude,
      );
      if (moveDist < 0.5) return;
    }

    _currentPosition = position;
    if (_kaabahPosition != null) {
      _distance = _calculateDistance(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
        _kaabahPosition!.latitude,
        _kaabahPosition!.longitude,
      );

      // Miqat Detection (150m)
      if (_distance <= _miqatRadius && !_miqatTriggered) {
        _miqatTriggered = true;
        NotificationService().showNotification(
          id: 0,
          title: "Miqat Approaching",
          body:
              "You are within 150m of the Kaabah. Please prepare your Niyyah.",
        );
        _queueGuidance(RitualGuidanceCatalog.miqatNiyyah);
      } else if (_distance > _miqatRadius) {
        _miqatTriggered = false;
      }

      GeofenceStatus newStatus = _distance <= _radius
          ? GeofenceStatus.inside
          : GeofenceStatus.outside;

      // Auto-lap detection: track angle around Kaabah when inside Tawaf zone
      if (newStatus == GeofenceStatus.inside && _kaabahPosition != null) {
        _detectTawafLapFromAngle(
          position.latitude,
          position.longitude,
          _kaabahPosition!.latitude,
          _kaabahPosition!.longitude,
        );
      } else if (newStatus == GeofenceStatus.outside) {
        // Reset auto-track state when leaving zone
        _tawafZoneEntryAngle = null;
        _previousTawafAngle = null;
        _hasCompletedFullCircleInZone = false;
      }

      _applyGeofenceStatus(newStatus);
    }
    notifyListeners();
  }

  // Real-time Tracking
  Future<void> startTracking() async {
    if (_positionStream != null) return; // Already tracking
    if (!await PrivacyConsentController.hasAcceptedLocationConsent()) return;

    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }

    // Web safe: Wrap getLastKnownPosition in try-catch as it's often unsupported on Web
    try {
      Position? lastPos = await Geolocator.getLastKnownPosition();
      if (lastPos != null) updatePosition(lastPos, force: true);
    } catch (e) {
      debugPrint("LastKnownPosition not supported: $e");
    }

    _positionStream =
        Geolocator.getPositionStream(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            distanceFilter: 1,
          ),
        ).listen((Position position) {
          updatePosition(position);
        });
  }

  void stopTracking() {
    _positionStream?.cancel();
    _positionStream = null;
  }

  void simulateStatus(GeofenceStatus newStatus) {
    _applyGeofenceStatus(newStatus);
    notifyListeners();
  }

  void incrementTawafLap() {
    if (_status != GeofenceStatus.inside ||
        _isTawafPaused ||
        _isTawafCompleted) {
      return;
    }
    if (_tawafLapCount < 7) {
      _tawafLapCount++;
      NotificationService().showNotification(
        id: 4,
        title: "Tawaf Round Completed",
        body: "You have completed $_tawafLapCount / 7 rounds.",
      );
      if (_tawafLapCount == 7) {
        _isTawafCompleted = true;
        _isTawafPaused = false;
        _tawafExitPromptPending = false;
        _queueGuidance(RitualGuidanceCatalog.tawafComplete);
        unawaited(clearTawafProgress());
      } else {
        _queueGuidance(RitualGuidanceCatalog.tawafRound);
        unawaited(saveTawafProgress());
      }
    }
    // Reset auto-track state after manual increment
    _tawafZoneEntryAngle = null;
    _previousTawafAngle = null;
    _hasCompletedFullCircleInZone = false;
    notifyListeners();
  }

  void _detectTawafLapFromAngle(
    double userLat,
    double userLng,
    double kaabahLat,
    double kaabahLng,
  ) {
    if (_isTawafPaused || _isTawafCompleted || _tawafLapCount >= 7) return;

    // Calculate angle in degrees (0-360) relative to Kaabah
    // atan2 gives angle from positive x-axis, we convert to compass-style
    double angleRad = atan2(userLng - kaabahLng, userLat - kaabahLat);
    double angleDeg = angleRad * 180 / 3.141592653589793;
    if (angleDeg < 0) angleDeg += 360;

    // Initialize on first entry into zone
    if (_tawafZoneEntryAngle == null) {
      _tawafZoneEntryAngle = angleDeg;
      _previousTawafAngle = angleDeg;
      return;
    }

    // Detect full circle: crossing from ~300-360° to ~0-60° (clockwise around Kaabah)
    double prev = _previousTawafAngle!;
    double curr = angleDeg;

    // Check for forward crossing (359° → 1°)
    bool forwardCrossing = (prev > 300 && prev <= 360) && (curr >= 0 && curr < 60);
    // Check for backward crossing as fallback (1° → 359°)
    bool backwardCrossing = (prev >= 0 && prev < 60) && (curr > 300 && curr <= 360);

    if (forwardCrossing || backwardCrossing) {
      // Only count forward crossings (clockwise walking direction)
      if (forwardCrossing && !_hasCompletedFullCircleInZone) {
        incrementTawafLap();
        _hasCompletedFullCircleInZone = true;
      }
      // Reset after crossing to allow next lap
      _tawafZoneEntryAngle = angleDeg;
    } else {
      // Reset circle completion flag if user hasn't completed full rotation
      double angleTraveled = (curr - _tawafZoneEntryAngle!).abs();
      if (angleTraveled < 300) {
        _hasCompletedFullCircleInZone = false;
      }
    }

    _previousTawafAngle = angleDeg;
  }

  void consumeGuidance() {
    _pendingGuidance = null;
    notifyListeners();
  }

  void resetTawaf() {
    _tawafLapCount = 0;
    _isTawafPaused = false;
    _isTawafCompleted = false;
    _tawafExitPromptPending = false;
    // Reset auto-lap tracking
    _tawafZoneEntryAngle = null;
    _previousTawafAngle = null;
    _hasCompletedFullCircleInZone = false;
    unawaited(clearTawafProgress());
    notifyListeners();
  }

  Future<void> loadTawafProgress() async {
    final prefs = await _getPrefsSafely();
    if (prefs == null) return;
    _tawafLapCount = prefs.getInt(_tawafLapCountKey) ?? 0;
    _isTawafPaused = prefs.getBool(_tawafIsPausedKey) ?? false;
    _isTawafCompleted = prefs.getBool(_tawafIsCompletedKey) ?? false;
    _tawafExitPromptPending = false;
    notifyListeners();
  }

  Future<void> saveTawafProgress() async {
    await _queueTawafPersistence(_writeTawafProgress);
  }

  Future<void> _writeTawafProgress() async {
    final prefs = await _getPrefsSafely();
    if (prefs == null) return;
    await prefs.setInt(_tawafLapCountKey, _tawafLapCount);
    await prefs.setBool(_tawafIsPausedKey, _isTawafPaused);
    await prefs.setBool(_tawafIsCompletedKey, _isTawafCompleted);
  }

  Future<void> continueTawafAfterExit() async {
    _tawafExitPromptPending = false;
    await saveTawafProgress();
    notifyListeners();
  }

  Future<void> endTawafForLater() async {
    _isTawafPaused = true;
    _tawafExitPromptPending = false;
    await saveTawafProgress();
    notifyListeners();
  }

  Future<void> clearTawafProgress() async {
    await _queueTawafPersistence(_deleteTawafProgress);
  }

  Future<void> _deleteTawafProgress() async {
    final prefs = await _getPrefsSafely();
    if (prefs == null) return;
    await prefs.remove(_tawafLapCountKey);
    await prefs.remove(_tawafIsPausedKey);
    await prefs.remove(_tawafIsCompletedKey);
  }

  Future<void> _queueTawafPersistence(Future<void> Function() action) {
    final nextWrite = _tawafPersistenceQueue.then((_) => action());
    _tawafPersistenceQueue = nextWrite.catchError((_) {});
    return nextWrite;
  }

  Future<SharedPreferences?> _getPrefsSafely() async {
    try {
      return await SharedPreferences.getInstance();
    } catch (e) {
      debugPrint('Tawaf local persistence unavailable: $e');
      return null;
    }
  }

  void _applyGeofenceStatus(GeofenceStatus newStatus) {
    if (newStatus == _status) {
      if (newStatus == GeofenceStatus.inside &&
          _isTawafPaused &&
          hasSavedTawafProgress) {
        _isTawafPaused = false;
        _tawafExitPromptPending = false;
        unawaited(saveTawafProgress());
      }
      return;
    }

    final previousStatus = _status;
    _status = newStatus;

    if (_status == GeofenceStatus.inside) {
      if (_isTawafPaused && hasSavedTawafProgress) {
        _isTawafPaused = false;
        _tawafExitPromptPending = false;
        unawaited(saveTawafProgress());
      }
      NotificationService().showNotification(
        id: 1,
        title: "Entered Tawaf Zone",
        body: "You are now within range of the Kaabah.",
      );
      _queueGuidance(RitualGuidanceCatalog.tawafStart);
    } else {
      if (previousStatus == GeofenceStatus.inside && hasSavedTawafProgress) {
        _isTawafPaused = true;
        _tawafExitPromptPending = true;
        unawaited(saveTawafProgress());
      }
      // Reset auto-lap tracking when exiting zone
      _tawafZoneEntryAngle = null;
      _previousTawafAngle = null;
      _hasCompletedFullCircleInZone = false;
      NotificationService().showNotification(
        id: 2,
        title: "Left Tawaf Zone",
        body: "Please stay close to the Kaabah.",
      );
    }
  }

  void _queueGuidance(RitualGuidance guidance) {
    if (_shownGuidanceIds.contains(guidance.id)) return;
    _shownGuidanceIds.add(guidance.id);
    _pendingGuidance = guidance;
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    super.dispose();
  }

  double _calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    var p = 0.017453292519943295;
    var c = cos;
    var a =
        0.5 -
        c((lat2 - lat1) * p) / 2 +
        c(lat1 * p) * c(lat2 * p) * (1 - c((lon2 - lon1) * p)) / 2;
    return 12742 * asin(sqrt(a)) * 1000;
  }
}
