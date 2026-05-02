import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'privacy_consent_controller.dart';

enum BackgroundGeofenceReadiness {
  disabled,
  missingConsent,
  serviceOff,
  permissionNeeded,
  ready,
}

class BackgroundGeofenceController with ChangeNotifier {
  BackgroundGeofenceController({
    Future<BackgroundGeofenceReadiness> Function()? readinessProbe,
  }) : _readinessProbe = readinessProbe;

  static const String _enabledKey = 'background_geofence_enabled_v1';
  final Future<BackgroundGeofenceReadiness> Function()? _readinessProbe;

  bool _isLoaded = false;
  bool _isEnabled = false;
  BackgroundGeofenceReadiness _readiness = BackgroundGeofenceReadiness.disabled;
  String _statusMessage =
      'Background monitoring is off. Tracking runs while practice screens are open.';

  bool get isLoaded => _isLoaded;
  bool get isEnabled => _isEnabled;
  BackgroundGeofenceReadiness get readiness => _readiness;
  String get statusMessage => _statusMessage;
  bool get canUseBackgroundMonitoring =>
      _isEnabled && _readiness == BackgroundGeofenceReadiness.ready;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _isEnabled = prefs.getBool(_enabledKey) ?? false;
    _isLoaded = true;
    await refreshStatus(notify: false);
    notifyListeners();
  }

  Future<void> setEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_enabledKey, enabled);
    _isEnabled = enabled;
    await refreshStatus(notify: false);
    notifyListeners();
  }

  Future<void> refreshStatus({bool notify = true}) async {
    if (!_isEnabled) {
      _readiness = BackgroundGeofenceReadiness.disabled;
      _statusMessage =
          'Background monitoring is off. Tracking runs while practice screens are open.';
      if (notify) notifyListeners();
      return;
    }

    _readiness = _readinessProbe == null
        ? await _probeDeviceReadiness()
        : await _readinessProbe();
    _statusMessage = _messageFor(_readiness);
    if (notify) notifyListeners();
  }

  Future<BackgroundGeofenceReadiness> _probeDeviceReadiness() async {
    final hasConsent =
        await PrivacyConsentController.hasAcceptedLocationConsent();
    if (!hasConsent) return BackgroundGeofenceReadiness.missingConsent;

    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return BackgroundGeofenceReadiness.serviceOff;

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return BackgroundGeofenceReadiness.permissionNeeded;
    }

    return BackgroundGeofenceReadiness.ready;
  }

  String _messageFor(BackgroundGeofenceReadiness readiness) {
    switch (readiness) {
      case BackgroundGeofenceReadiness.disabled:
        return 'Background monitoring is off. Tracking runs while practice screens are open.';
      case BackgroundGeofenceReadiness.missingConsent:
        return 'Location consent is required before background monitoring can run.';
      case BackgroundGeofenceReadiness.serviceOff:
        return 'Device location services are turned off.';
      case BackgroundGeofenceReadiness.permissionNeeded:
        return 'Location permission is needed before monitoring can continue.';
      case BackgroundGeofenceReadiness.ready:
        return 'Background-ready mode is enabled. Active ritual screens will keep geofence monitoring prepared.';
    }
  }
}
