import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:math' show cos, sqrt, asin;
import '../../../core/services/notification_service.dart';

enum HillTarget { safa, marwa }

class SaiProvider with ChangeNotifier {
  Position? _currentPosition;
  Position? _safaPosition;
  Position? _marwaPosition;
  int _saiLapCount = 0;
  HillTarget _nextTarget = HillTarget.marwa; // Usually start at Safa, go to Marwa
  final double _radius = 15.0; // Hills might need a bit more radius than Kaabah

  Position? get currentPosition => _currentPosition;
  int get saiLapCount => _saiLapCount;
  HillTarget get nextTarget => _nextTarget;
  double get radius => _radius;

  // Initialize hills for simulation
  void initHillsForDemo() {
    _safaPosition = Position(
      latitude: 21.4221, 
      longitude: 39.8272,
      timestamp: DateTime.now(),
      accuracy: 0, altitude: 0, heading: 0, speed: 0, speedAccuracy: 0,
      altitudeAccuracy: 0, headingAccuracy: 0,
    );
    _marwaPosition = Position(
      latitude: 21.4248, 
      longitude: 39.8267,
      timestamp: DateTime.now(),
      accuracy: 0, altitude: 0, heading: 0, speed: 0, speedAccuracy: 0,
      altitudeAccuracy: 0, headingAccuracy: 0,
    );
    _saiLapCount = 0;
    _nextTarget = HillTarget.marwa;
    notifyListeners();
  }

  void updatePosition(Position position) {
    _currentPosition = position;
    _checkArrival();
    notifyListeners();
  }

  void _checkArrival() {
    if (_currentPosition == null) return;

    final targetPos = _nextTarget == HillTarget.marwa ? _marwaPosition : _safaPosition;
    if (targetPos == null) return;

    double distance = _calculateDistance(
      _currentPosition!.latitude,
      _currentPosition!.longitude,
      targetPos.latitude,
      targetPos.longitude,
    );

    if (distance <= _radius) {
      _reachHill();
    }
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

  // Simulation methods
  void simulateReachHill() {
    _reachHill();
  }

  void resetSai() {
    _saiLapCount = 0;
    _nextTarget = HillTarget.marwa;
    notifyListeners();
  }

  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    var p = 0.017453292519943295;
    var c = cos;
    var a = 0.5 -
        c((lat2 - lat1) * p) / 2 +
        c(lat1 * p) * c(lat2 * p) * (1 - c((lon2 - lon1) * p)) / 2;
    return 12742 * asin(sqrt(a)) * 1000;
  }
}
