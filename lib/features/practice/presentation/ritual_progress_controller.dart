import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../domain/practice_mode.dart';

class RitualProgressController with ChangeNotifier {
  static const String _modeKey = 'practice_mode';
  static const String _niyyahCompletedKey = 'niyyah_completed';
  static const String _tawafCompletedKey = 'ritual_tawaf_completed';

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

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _mode = PracticeMode.fromValue(prefs.getString(_modeKey));
    _niyyahCompleted = prefs.getBool(_niyyahCompletedKey) ?? false;
    _tawafCompleted = prefs.getBool(_tawafCompletedKey) ?? false;
    _isLoaded = true;
    notifyListeners();
  }

  Future<void> setMode(PracticeMode mode) async {
    _mode = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_modeKey, mode.name);
    notifyListeners();
  }

  Future<void> markNiyyahCompleted() async {
    _niyyahCompleted = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_niyyahCompletedKey, true);
    notifyListeners();
  }

  Future<void> markTawafCompleted() async {
    _tawafCompleted = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_tawafCompletedKey, true);
    notifyListeners();
  }

  Future<void> resetLocationProgress() async {
    _niyyahCompleted = false;
    _tawafCompleted = false;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_niyyahCompletedKey, false);
    await prefs.setBool(_tawafCompletedKey, false);
    notifyListeners();
  }
}
