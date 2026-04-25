import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:math' show cos, sqrt, asin;
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

  Position? get currentPosition => _currentPosition;
  Position? get kaabahPosition => _kaabahPosition;
  GeofenceStatus get status => _status;
  double get distance => _distance;
  double get radius => _radius;
  int get tawafLapCount => _tawafLapCount;

  // Set the "Home Kaabah" point manually
  Future<void> setKaabahPoint() async {
    // FALLBACK FOR WINDOWS/DEMO: 
    // If we are on Windows or just want to demo, we can use a dummy position 
    // if the real GPS fails.
    try {
      bool serviceEnabled;
      LocationPermission permission;

      serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _setDummyKaabah();
        return;
      }

      permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _setDummyKaabah();
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _setDummyKaabah();
        return;
      }

      _kaabahPosition = await Geolocator.getCurrentPosition();
      _status = GeofenceStatus.inside;
      notifyListeners();
    } catch (e) {
      debugPrint("GPS Error: $e. Falling back to dummy location for demo.");
      _setDummyKaabah();
    }
  }

  // Helper to set a dummy location so the app doesn't crash during demo
  void _setDummyKaabah() {
    _kaabahPosition = Position(
      latitude: 21.4225, // Mecca Latitude
      longitude: 39.8262, // Mecca Longitude
      timestamp: DateTime.now(),
      accuracy: 0,
      altitude: 0,
      heading: 0,
      speed: 0,
      speedAccuracy: 0,
      altitudeAccuracy: 0,
      headingAccuracy: 0,
    );
    _status = GeofenceStatus.inside;
    notifyListeners();
  }

  // Update current position and check geofence
  void updatePosition(Position position) {
    _currentPosition = position;
    if (_kaabahPosition != null) {
      _distance = _calculateDistance(
        _kaabahPosition!.latitude,
        _kaabahPosition!.longitude,
        _currentPosition!.latitude,
        _currentPosition!.longitude,
      );

      if (_distance <= _radius) {
        if (_status != GeofenceStatus.inside) {
          NotificationService().showNotification(
            id: 1,
            title: "Welcome to Mataf",
            body: "You are now inside the Kaabah geofence radius.",
          );
        }
        _status = GeofenceStatus.inside;
      } else {
        _status = GeofenceStatus.outside;
      }
    }
    notifyListeners();
  }

  // Simulation methods for Demo/FYP
  void simulateStatus(GeofenceStatus newStatus) {
    _status = newStatus;
    notifyListeners();
  }

  // Lap Management
  void incrementTawafLap() {
    if (_tawafLapCount < 7) {
      _tawafLapCount++;
      NotificationService().showNotification(
        id: 2,
        title: "Tawaf Update",
        body: "Round $_tawafLapCount completed!",
      );
      if (_tawafLapCount == 7) {
        NotificationService().showNotification(
          id: 3,
          title: "Tawaf Completed",
          body: "Alhamdulillah, you have finished 7 rounds of Tawaf.",
        );
      }
      notifyListeners();
    }
  }

  void resetTawaf() {
    _tawafLapCount = 0;
    notifyListeners();
  }

  // Helper: Haversine formula to calculate distance in meters
  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    var p = 0.017453292519943295;
    var c = cos;
    var a = 0.5 -
        c((lat2 - lat1) * p) / 2 +
        c(lat1 * p) * c(lat2 * p) * (1 - c((lon2 - lon1) * p)) / 2;
    return 12742 * asin(sqrt(a)) * 1000;
  }
}
