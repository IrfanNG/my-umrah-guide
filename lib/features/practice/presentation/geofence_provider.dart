import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:math' show cos, sqrt, asin;
import 'dart:async';
import 'package:flutter/foundation.dart'; // To check kIsWeb or platform
import '../../../core/services/notification_service.dart';

enum GeofenceStatus { initial, inside, outside }

class GeofenceProvider with ChangeNotifier {
  Position? _currentPosition;
  Position? _kaabahPosition;
  GeofenceStatus _status = GeofenceStatus.initial;
  final double _radius = 10.0; // Default 10 meters
  double _distance = 0.0;
  int _tawafLapCount = 0;
  StreamSubscription<Position>? _positionStream;
  Timer? _pollingTimer;

  GeofenceProvider() {
    startTracking();
    _startPolling();
  }

  Position? get currentPosition => _currentPosition;
  Position? get kaabahPosition => _kaabahPosition;
  GeofenceStatus get status => _status;
  double get radius => _radius;
  double get distance => _distance;
  int get tawafLapCount => _tawafLapCount;

  // Set the reference point (Kaabah) to current user location
  Future<void> setKaabahPoint() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return;
      }

      _kaabahPosition = await Geolocator.getCurrentPosition();
      _status = GeofenceStatus.inside;
      startTracking(); // Start tracking after setting point
      notifyListeners();
    } catch (e) {
      debugPrint("GPS Error: $e. Falling back to dummy location for demo.");
      _setDummyKaabah();
    }
  }

  void setManualKaabahPoint(double lat, double lng) {
    _kaabahPosition = Position(
      latitude: lat,
      longitude: lng,
      timestamp: DateTime.now(),
      accuracy: 0, altitude: 0, heading: 0, speed: 0, speedAccuracy: 0,
      altitudeAccuracy: 0, headingAccuracy: 0,
    );
    _status = GeofenceStatus.inside; // Assume user is inside if they just pinned it nearby
    notifyListeners();
  }

  void _setDummyKaabah() {
    _kaabahPosition = Position(
      latitude: 21.4225, // Mecca Latitude
      longitude: 39.8262, // Mecca Longitude
      timestamp: DateTime.now(),
      accuracy: 0, altitude: 0, heading: 0, speed: 0, speedAccuracy: 0,
      altitudeAccuracy: 0, headingAccuracy: 0,
    );
    _status = GeofenceStatus.inside;
    notifyListeners();
  }

  void updatePosition(Position position) {
    _currentPosition = position;
    if (_kaabahPosition != null) {
      _distance = _calculateDistance(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
        _kaabahPosition!.latitude,
        _kaabahPosition!.longitude,
      );

      if (_distance <= _radius) {
        if (_status != GeofenceStatus.inside) {
          _status = GeofenceStatus.inside;
          NotificationService().showNotification(
            id: 1,
            title: "Entered Mataf Zone",
            body: "You are now within range of the Kaabah.",
          );
        }
      } else {
        if (_status != GeofenceStatus.outside) {
          _status = GeofenceStatus.outside;
          NotificationService().showNotification(
            id: 2,
            title: "Left Mataf Zone",
            body: "Please stay close to the Kaabah for accurate tracking.",
          );
        }
      }
    }
    notifyListeners();
  }

  // Simulation methods for UI testing
  void simulateStatus(GeofenceStatus newStatus) {
    _status = newStatus;
    if (_status == GeofenceStatus.inside) {
      NotificationService().showNotification(
        id: 3,
        title: "Simulation: Inside",
        body: "Entering the Kaabah zone...",
      );
    }
    notifyListeners();
  }

  void incrementTawafLap() {
    if (_tawafLapCount < 7) {
      _tawafLapCount++;
      NotificationService().showNotification(
        id: 4,
        title: "Tawaf Round Completed",
        body: "You have completed $_tawafLapCount / 7 rounds.",
      );
      
      if (_tawafLapCount == 7) {
        NotificationService().showNotification(
          id: 5,
          title: "Tawaf Completed",
          body: "Alhamdulillah, you have finished 7 rounds of Tawaf.",
        );
      }
    }
    notifyListeners();
  }

  void resetTawaf() {
    _tawafLapCount = 0;
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

  // Helper: Haversine formula to calculate distance in meters
  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    var p = 0.017453292519943295;
    var c = cos;
    var a = 0.5 - c((lat2 - lat1) * p) / 2 +
        c(lat1 * p) * c(lat2 * p) *
            (1 - c((lon2 - lon1) * p)) / 2;
    return 12742 * asin(sqrt(a)) * 1000;
  }
}
