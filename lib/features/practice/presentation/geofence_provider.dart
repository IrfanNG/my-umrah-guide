import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:math' show cos, sqrt, asin;
import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../../core/services/notification_service.dart';

enum GeofenceStatus { initial, inside, outside }

class GeofenceProvider with ChangeNotifier {
  Position? _currentPosition;
  Position? _kaabahPosition;
  GeofenceStatus _status = GeofenceStatus.initial;
  bool _miqatTriggered = false; // New: Miqat status
  
  final double _radius = 75.0; // Tawaf radius per PDF
  final double _miqatRadius = 150.0; // Miqat radius per PDF Table 5
  
  double _distance = 0.0;
  int _tawafLapCount = 0;
  StreamSubscription<Position>? _positionStream;

  Position? get currentPosition => _currentPosition;
  Position? get kaabahPosition => _kaabahPosition;
  GeofenceStatus get status => _status;
  bool get miqatTriggered => _miqatTriggered; // Getter for Miqat
  double get radius => _radius;
  double get distance => _distance;
  int get tawafLapCount => _tawafLapCount;

  // Set the reference point (Kaabah) to current user location
  Future<void> setKaabahPoint() async {
    // Optimization: Use cached stream position for instant feedback
    if (_currentPosition != null) {
      _kaabahPosition = _currentPosition;
      _status = GeofenceStatus.inside;
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
      _status = GeofenceStatus.inside;
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
      accuracy: 0, altitude: 0, heading: 0, speed: 0, speedAccuracy: 0,
      altitudeAccuracy: 0, headingAccuracy: 0,
    );
    _status = GeofenceStatus.inside;
    notifyListeners();
  }

  void _setDummyKaabah() {
    _kaabahPosition = Position(
      latitude: 21.4225,
      longitude: 39.8262,
      timestamp: DateTime.now(),
      accuracy: 0, altitude: 0, heading: 0, speed: 0, speedAccuracy: 0,
      altitudeAccuracy: 0, headingAccuracy: 0,
    );
    _status = GeofenceStatus.inside;
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
          body: "You are within 150m of the Kaabah. Please prepare your Niyyah.",
        );
      } else if (_distance > _miqatRadius) {
        _miqatTriggered = false;
      }

      GeofenceStatus newStatus = _distance <= _radius 
          ? GeofenceStatus.inside 
          : GeofenceStatus.outside;

      if (newStatus != _status) {
        _status = newStatus;
        if (_status == GeofenceStatus.inside) {
          NotificationService().showNotification(
            id: 1, title: "Entered Tawaf Zone", body: "You are now within range of the Kaabah.",
          );
        } else {
          NotificationService().showNotification(
            id: 2, title: "Left Tawaf Zone", body: "Please stay close to the Kaabah.",
          );
        }
      }
    }
    notifyListeners();
  }

  // Real-time Tracking
  Future<void> startTracking() async {
    if (_positionStream != null) return; // Already tracking

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

    _positionStream = Geolocator.getPositionStream(
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
    _status = newStatus;
    notifyListeners();
  }

  void incrementTawafLap() {
    if (_tawafLapCount < 7) {
      _tawafLapCount++;
      NotificationService().showNotification(
        id: 4, title: "Tawaf Round Completed", body: "You have completed $_tawafLapCount / 7 rounds.",
      );
    }
    notifyListeners();
  }

  void resetTawaf() {
    _tawafLapCount = 0;
    notifyListeners();
  }

  @override
  void dispose() {
    _positionStream?.cancel();
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
