import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../domain/user_profile.dart';

class GuestSessionController with ChangeNotifier {
  static const String _guestModeKey = 'guest_mode_enabled_v1';

  bool _isLoaded = false;
  bool _isGuestMode = false;

  bool get isLoaded => _isLoaded;
  bool get isGuestMode => _isGuestMode;
  bool get hasActiveGuestSession => _isGuestMode;

  static const UserProfile guestProfile = UserProfile(
    uid: 'guest-demo',
    email: 'guest@myumrahguide.local',
    role: UserRole.user,
    age: 30,
    abilityLevel: AbilityLevel.medium,
    healthConditions: '',
    heightCm: 170,
    weightKg: 70,
  );

  String get storageNamespace => _isGuestMode ? 'guest_' : 'user_';

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _isGuestMode = prefs.getBool(_guestModeKey) ?? false;
    _isLoaded = true;
    notifyListeners();
  }

  Future<void> ensureLoaded() async {
    if (_isLoaded) return;
    await load();
  }

  Future<void> enterGuestMode() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_guestModeKey, true);
    _isGuestMode = true;
    _isLoaded = true;
    notifyListeners();
  }

  Future<void> exitGuestMode() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_guestModeKey, false);
    _isGuestMode = false;
    _isLoaded = true;
    notifyListeners();
  }
}
