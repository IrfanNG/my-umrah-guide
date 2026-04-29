import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:math' show cos, sqrt, asin;
import 'dart:async';
import '../../../core/services/notification_service.dart';
import 'guidance/ritual_guidance.dart';

enum HillTarget { safa, marwa }

class SaiProvider with ChangeNotifier {
  Position? _currentPosition;
  Position? _safaPosition;
  Position? _marwaPosition;
  int _saiLapCount = 0;
  bool _hasReachedSafaForCurrentLap = false;
  bool _hasReachedMarwaForCurrentLap = false;
  HillTarget _nextTarget =
      HillTarget.marwa; // Usually start at Safa, go to Marwa
  final double _radius =
      50.0; // 50m radius covers the 100m width corridor specified in PDF
  RitualGuidance? _pendingGuidance;
  final Set<String> _shownGuidanceIds = <String>{};
  StreamSubscription<Position>? _positionStream;

  Position? get currentPosition => _currentPosition;
  Position? get safaPosition => _safaPosition;
  Position? get marwaPosition => _marwaPosition;
  int get saiLapCount => _saiLapCount;
  HillTarget get nextTarget => _nextTarget;
  double get radius => _radius;
  RitualGuidance? get pendingGuidance => _pendingGuidance;
  bool get hasReachedSafaForCurrentLap => _hasReachedSafaForCurrentLap;
  bool get hasReachedMarwaForCurrentLap => _hasReachedMarwaForCurrentLap;
  String get currentLapProgressLabel {
    if (_saiLapCount >= 7) return 'Sa\'i completed';
    if (_hasReachedSafaForCurrentLap) {
      return 'Current lap: Safa reached, Marwa pending';
    }
    if (_hasReachedMarwaForCurrentLap) {
      return 'Current lap: Marwa reached, Safa pending';
    }
    return 'Current lap: reach Safa and Marwa';
  }

  Future<void> setSafaPoint() async {
    if (_currentPosition != null) {
      _safaPosition = _currentPosition;
      notifyListeners();
      return;
    }
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return;
      }
      Position pos = await Geolocator.getCurrentPosition().timeout(
        const Duration(seconds: 3),
      );
      updatePosition(pos, force: true);
      _safaPosition = pos;
      notifyListeners();
    } catch (e) {
      debugPrint("GPS Error/Timeout Safa: $e");
    }
  }

  void setManualSafaPoint(double lat, double lng) {
    _safaPosition = Position(
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
    notifyListeners();
  }

  Future<void> setMarwaPoint() async {
    if (_currentPosition != null) {
      _marwaPosition = _currentPosition;
      notifyListeners();
      return;
    }
    try {
      Position pos = await Geolocator.getCurrentPosition().timeout(
        const Duration(seconds: 3),
      );
      updatePosition(pos, force: true);
      _marwaPosition = pos;
      notifyListeners();
    } catch (e) {
      debugPrint("GPS Error/Timeout Marwa: $e");
    }
  }

  void setManualMarwaPoint(double lat, double lng) {
    _marwaPosition = Position(
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
    notifyListeners();
  }

  void updatePosition(Position position, {bool force = false}) {
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

    Position? targetPos = _nextTarget == HillTarget.marwa
        ? _marwaPosition
        : _safaPosition;
    if (targetPos != null) {
      double dist = _calculateDistance(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
        targetPos.latitude,
        targetPos.longitude,
      );
      if (dist <= _radius) {
        _reachHill();
      }
    }
    notifyListeners();
  }

  void _reachHill() {
    if (_saiLapCount >= 7) return;

    final reachedTarget = _nextTarget;
    final hillName = reachedTarget == HillTarget.marwa ? "Marwa" : "Safa";

    if (reachedTarget == HillTarget.marwa) {
      _hasReachedMarwaForCurrentLap = true;
      _queueGuidance(RitualGuidanceCatalog.saiMarwa);
    } else {
      _hasReachedSafaForCurrentLap = true;
      _queueGuidance(RitualGuidanceCatalog.saiSafa);
    }

    NotificationService().showNotification(
      id: 10 + (_saiLapCount * 2) + (reachedTarget == HillTarget.marwa ? 1 : 2),
      title: "Reached $hillName",
      body: currentLapProgressLabel,
    );

    if (_hasReachedSafaForCurrentLap && _hasReachedMarwaForCurrentLap) {
      _saiLapCount++;
      _hasReachedSafaForCurrentLap = false;
      _hasReachedMarwaForCurrentLap = false;

      NotificationService().showNotification(
        id: 40 + _saiLapCount,
        title: "Sa'i Lap Completed",
        body: "You have completed $_saiLapCount / 7 Sa'i laps.",
      );

      if (_saiLapCount == 7) {
        NotificationService().showNotification(
          id: 20,
          title: "Sa'i Completed",
          body: "Alhamdulillah, you have finished 7 laps of Sa'i.",
        );
        _queueGuidance(RitualGuidanceCatalog.saiComplete);
      }
    }

    _nextTarget = reachedTarget == HillTarget.marwa
        ? HillTarget.safa
        : HillTarget.marwa;
  }

  void simulateReachHill() {
    _reachHill();
    notifyListeners();
  }

  void resetSai() {
    _saiLapCount = 0;
    _hasReachedSafaForCurrentLap = false;
    _hasReachedMarwaForCurrentLap = false;
    _nextTarget = HillTarget.marwa;
    notifyListeners();
  }

  void consumeGuidance() {
    _pendingGuidance = null;
    notifyListeners();
  }

  Future<void> startTracking() async {
    if (_positionStream != null) return;
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }

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

  void _queueGuidance(RitualGuidance guidance) {
    if (_shownGuidanceIds.contains(guidance.id)) return;
    _shownGuidanceIds.add(guidance.id);
    _pendingGuidance = guidance;
  }
}
