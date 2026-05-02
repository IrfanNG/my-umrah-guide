import 'dart:convert';

import 'package:http/http.dart' as http;

import '../domain/adaptive_schedule.dart';

class CrowdDensityRepository {
  CrowdDensityRepository({
    http.Client? client,
    String? baseUrl,
    DateTime Function()? now,
  }) : _client = client ?? http.Client(),
       _baseUrl = baseUrl ?? 'http://127.0.0.1:8000',
       _now = now ?? DateTime.now;

  final http.Client _client;
  final String _baseUrl;
  final DateTime Function() _now;

  Future<AdaptiveScheduleAdvice> getAdvice(String ritualType) async {
    try {
      final response = await _client
          .get(Uri.parse('$_baseUrl/crowd-density?ritualType=$ritualType'))
          .timeout(const Duration(seconds: 4));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return AdaptiveScheduleAdvice.fromJson(
          jsonDecode(response.body) as Map<String, dynamic>,
        );
      }
    } catch (_) {
      // Local API is optional for FYP demos; keep deterministic guidance.
    }

    return _fallbackAdvice(ritualType);
  }

  AdaptiveScheduleAdvice _fallbackAdvice(String ritualType) {
    final hour = _now().hour;
    final densityScore = _scoreForHour(hour);
    final crowdLevel = densityScore >= 0.72
        ? CrowdLevel.high
        : densityScore >= 0.45
        ? CrowdLevel.moderate
        : CrowdLevel.low;

    return AdaptiveScheduleAdvice(
      ritualType: ritualType,
      crowdLevel: crowdLevel,
      densityScore: densityScore,
      recommendedWindow: _windowFor(crowdLevel),
      rerouteAdvice: _adviceFor(ritualType, crowdLevel),
      generatedAt: _now(),
    );
  }

  double _scoreForHour(int hour) {
    if (hour >= 10 && hour <= 14) return 0.82;
    if (hour >= 19 && hour <= 23) return 0.76;
    if (hour >= 5 && hour <= 8) return 0.58;
    return 0.32;
  }

  String _windowFor(CrowdLevel level) {
    switch (level) {
      case CrowdLevel.low:
        return 'Current window is suitable';
      case CrowdLevel.moderate:
        return 'Proceed slowly or wait 30-45 minutes';
      case CrowdLevel.high:
        return 'Delay if possible; retry during early morning or late night';
    }
  }

  String _adviceFor(String ritualType, CrowdLevel level) {
    final ritualLabel = ritualType == 'sai' ? 'Sa\'i corridor' : 'Tawaf area';
    switch (level) {
      case CrowdLevel.low:
        return '$ritualLabel crowd pressure is low. Continue with normal pacing.';
      case CrowdLevel.moderate:
        return '$ritualLabel is moderately crowded. Use steady pacing and avoid dense clusters.';
      case CrowdLevel.high:
        return '$ritualLabel is crowded. Use outer lanes, pause at safe edges, or delay the ritual window.';
    }
  }
}
