import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../domain/practice_mode.dart';
import 'guest_session_controller.dart';

class RitualProgressController with ChangeNotifier {
  RitualProgressController({GuestSessionController? guestSessionController})
      : _guestSessionController = guestSessionController {
    _guestSessionController?.addListener(_handleSessionChanged);
  }

  static const String _modeKey = 'practice_mode';
  static const String _niyyahCompletedKey = 'niyyah_completed';
  static const String _tawafCompletedKey = 'ritual_tawaf_completed';

  final GuestSessionController? _guestSessionController;

  PracticeMode _mode = PracticeMode.manual;
  bool _niyyahCompleted = false;
  bool _tawafCompleted = false;
  bool _isLoaded = false;

  PracticeMode get mode => _mode;
  bool get niyyahCompleted => _niyyahCompleted;
  bool get tawafCompleted => _tawafCompleted;
  bool get isLoaded => _isLoaded;

  bool get canOpenTawaf {
    return _mode == PracticeMode.manual || _niyyahCompleted;
  }

  bool get canOpenSai {
    return _mode == PracticeMode.manual || _tawafCompleted;
  }

  String get _keyPrefix =>
      _guestSessionController?.storageNamespace ?? 'user_';

  Future<void> load() async {
    await _guestSessionController?.ensureLoaded();
    final prefs = await SharedPreferences.getInstance();
    _mode = PracticeMode.fromValue(prefs.getString('$_keyPrefix$_modeKey'));
    _niyyahCompleted = prefs.getBool('$_keyPrefix$_niyyahCompletedKey') ?? false;
    _tawafCompleted = prefs.getBool('$_keyPrefix$_tawafCompletedKey') ?? false;
    _isLoaded = true;
    notifyListeners();
  }

  Future<void> setMode(PracticeMode mode) async {
    _mode = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('$_keyPrefix$_modeKey', mode.name);
    notifyListeners();
  }

  Future<void> markNiyyahCompleted() async {
    _niyyahCompleted = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('$_keyPrefix$_niyyahCompletedKey', true);
    notifyListeners();
  }

  Future<void> markTawafCompleted() async {
    _tawafCompleted = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('$_keyPrefix$_tawafCompletedKey', true);
    notifyListeners();
  }

  Future<void> resetLocationProgress() async {
    _niyyahCompleted = false;
    _tawafCompleted = false;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('$_keyPrefix$_niyyahCompletedKey', false);
    await prefs.setBool('$_keyPrefix$_tawafCompletedKey', false);
    notifyListeners();
  }

  void _handleSessionChanged() {
    if (_isLoaded) {
      unawaited(load());
    }
  }

  @override
  void dispose() {
    _guestSessionController?.removeListener(_handleSessionChanged);
    super.dispose();
  }
}
