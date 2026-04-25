import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:math' show cos, sqrt, asin;
import 'dart:async';
import '../../../core/services/notification_service.dart';

enum HillTarget { safa, marwa }

class SaiProvider with ChangeNotifier {
  Position? _currentPosition;
  Position? _safaPosition;
  Position? _marwaPosition;
  int _saiLapCount = 0;
  HillTarget _nextTarget = HillTarget.marwa; // Usually start at Safa, go to Marwa
  double _radius = 15.0; // Dynamic radius
  StreamSubscription<Position>? _positionStream;
  Timer? _pollingTimer;

  SaiProvider() {
    startTracking();
    _startPolling();
  }

  Position? get currentPosition => _currentPosition;
  Position? get safaPosition => _safaPosition;
  Position? get marwaPosition => _marwaPosition;
  int get saiLapCount => _saiLapCount;
  HillTarget get nextTarget => _nextTarget;
  double get radius => _radius;

  // Initialize hills for local practice
  Future<void> initHillsLocally() async {
    try {
      Position current = await Geolocator.getCurrentPosition();
      _safaPosition = current;
      // Set Marwa 50 meters North for practice
      _marwaPosition = Position(
        latitude: current.latitude + 0.00045, // approx 50m
        longitude: current.longitude,
        timestamp: DateTime.now(),
        accuracy: 0, altitude: 0, heading: 0, speed: 0, speedAccuracy: 0,
        altitudeAccuracy: 0, headingAccuracy: 0,
      );
      _saiLapCount = 0;
      _nextTarget = HillTarget.marwa;
      startTracking();
      notifyListeners();
    } catch (e) {
      debugPrint("Error setting local hills: $e");
    }
  }

  void setSafaPoint(Position pos) {
    _safaPosition = pos;
    notifyListeners();
  }

  void setManualSafaPoint(double lat, double lng) {
    _safaPosition = Position(
      latitude: lat,
      longitude: lng,
      timestamp: DateTime.now(),
      accuracy: 0, altitude: 0, heading: 0, speed: 0, speedAccuracy: 0,
      altitudeAccuracy: 0, headingAccuracy: 0,
    );
    notifyListeners();
  }

  void setMarwaPoint(Position pos) {
    _marwaPosition = pos;
    notifyListeners();
  }

  void setManualMarwaPoint(double lat, double lng) {
    _marwaPosition = Position(
      latitude: lat,
      longitude: lng,
      timestamp: DateTime.now(),
      accuracy: 0, altitude: 0, heading: 0, speed: 0, speedAccuracy: 0,
      altitudeAccuracy: 0, headingAccuracy: 0,
    );
    notifyListeners();
  }

  void updatePosition(Position position) {
    _currentPosition = position;
    
    // Dynamic radius based on accuracy (max 30m)
    _radius = (position.accuracy > 15) ? position.accuracy.clamp(15, 30) : 15.0;

    // If Sa'i hasn't started, check if user is at Safa
    if (_saiLapCount == 0 && _safaPosition != null) {
      double distToSafa = _calculateDistance(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
        _safaPosition!.latitude,
        _safaPosition!.longitude,
      );
      if (distToSafa <= _radius) {
        // Just initialize, don't count as lap yet (unless you want Safa to be Lap 0)
        debugPrint("User at Safa. Ready to start.");
      }
    }

    // Check if reached next target
    Position? targetPos = _nextTarget == HillTarget.marwa ? _marwaPosition : _safaPosition;
    
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
    if (_saiLapCount < 7) {
      _saiLapCount++;
      String hillName = _nextTarget == HillTarget.marwa ? "Marwa" : "Safa";
      NotificationService().showNotification(
        id: 10 + _saiLapCount,
        title: "Reached $hillName",
        body: "Lap $_saiLapCount completed!",
      );
      
      if (_saiLapCount == 7) {
        NotificationService().showNotification(
          id: 20,
          title: "Sa'i Completed",
          body: "Alhamdulillah, you have finished 7 laps of Sa'i.",
        );
      }
      
      _nextTarget = _nextTarget == HillTarget.marwa ? HillTarget.safa : HillTarget.marwa;
      notifyListeners();
    }
  }

  // Simulation
  void simulateReachHill() {
    _reachHill();
  }

  void resetSai() {
    _saiLapCount = 0;
    _nextTarget = HillTarget.marwa;
    notifyListeners();
  }

  // Real-time Tracking
  Future<void> startTracking() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }
    
    if (permission == LocationPermission.deniedForever) return;

    // Get initial position immediately
    try {
      Position initial = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );
      updatePosition(initial);
    } catch (e) {
      debugPrint("Initial position error: $e");
    }

    _positionStream?.cancel();
    _positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 1, // Update every 1 meter
      ),
    ).listen((Position position) {
      updatePosition(position);
    });
  }

  void stopTracking() {
    _positionStream?.cancel();
    _positionStream = null;
    _pollingTimer?.cancel();
  }

  void _startPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(seconds: 5), (timer) async {
      try {
        Position pos = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
        );
        updatePosition(pos);
      } catch (e) {
        debugPrint("Polling error: $e");
      }
    });
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    _pollingTimer?.cancel();
    super.dispose();
  }

  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    var p = 0.017453292519943295;
    var c = cos;
    var a = 0.5 - c((lat2 - lat1) * p) / 2 +
        c(lat1 * p) * c(lat2 * p) *
            (1 - c((lon2 - lon1) * p)) / 2;
    return 12742 * asin(sqrt(a)) * 1000;
  }
}
