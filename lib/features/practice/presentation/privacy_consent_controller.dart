import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PrivacyConsentController with ChangeNotifier {
  static const String locationConsentKey = 'privacy_location_consent_v1';

  bool _isLoaded = false;
  bool _hasLocationConsent = false;

  bool get isLoaded => _isLoaded;
  bool get hasLocationConsent => _hasLocationConsent;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _hasLocationConsent = prefs.getBool(locationConsentKey) ?? false;
    _isLoaded = true;
    notifyListeners();
  }

  Future<void> acceptLocationConsent() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(locationConsentKey, true);
    _hasLocationConsent = true;
    _isLoaded = true;
    notifyListeners();
  }

  Future<void> revokeLocationConsent() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(locationConsentKey, false);
    _hasLocationConsent = false;
    _isLoaded = true;
    notifyListeners();
  }

  static Future<bool> hasAcceptedLocationConsent() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(locationConsentKey) ?? false;
  }
}
