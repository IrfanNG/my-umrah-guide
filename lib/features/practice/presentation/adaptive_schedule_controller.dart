import 'package:flutter/material.dart';

import '../data/crowd_density_repository.dart';
import '../domain/adaptive_schedule.dart';

class AdaptiveScheduleController with ChangeNotifier {
  AdaptiveScheduleController({CrowdDensityRepository? repository})
    : _repository = repository ?? CrowdDensityRepository();

  final CrowdDensityRepository _repository;
  final Map<String, AdaptiveScheduleAdvice> _adviceByRitual = {};
  final Set<String> _loadingRituals = {};
  String? _errorMessage;

  String? get errorMessage => _errorMessage;

  AdaptiveScheduleAdvice? adviceFor(String ritualType) {
    return _adviceByRitual[ritualType];
  }

  bool isLoading(String ritualType) {
    return _loadingRituals.contains(ritualType);
  }

  Future<void> loadAdvice(String ritualType) async {
    if (isLoading(ritualType)) return;

    _loadingRituals.add(ritualType);
    _errorMessage = null;
    notifyListeners();

    try {
      _adviceByRitual[ritualType] = await _repository.getAdvice(ritualType);
    } catch (_) {
      _errorMessage = 'Adaptive scheduling is unavailable right now.';
    } finally {
      _loadingRituals.remove(ritualType);
      notifyListeners();
    }
  }
}
