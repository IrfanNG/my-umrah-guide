import 'dart:convert';
import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;

import '../domain/ritual_recommendation.dart';
import '../domain/user_profile.dart';

class RecommendationRepository {
  RecommendationRepository({
    FirebaseFirestore? firestore,
    http.Client? client,
    String? baseUrl,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _client = client ?? http.Client(),
       _baseUrl = baseUrl ?? 'http://127.0.0.1:8000';

  final FirebaseFirestore _firestore;
  final http.Client _client;
  final String _baseUrl;

  static const double _tawafFallbackRadius = 64.0;
  static const double _tawafMinRadius = 15.0;
  static const double _tawafMaxRadius = 75.0;
  static const double _saiFixedDistance = 3100.0;
  static const double _tawafPaceMultiplier = 0.90;
  static const double _saiPaceMultiplier = 0.95;

  Future<RitualRecommendation> getRecommendation({
    required UserProfile profile,
    required RitualType ritualType,
    double? currentRadius,
  }) async {
    try {
      final body = <String, dynamic>{
        'ritualType': ritualType.name,
        'age': profile.age,
        'abilityLevel': profile.abilityLevel.name,
        'healthConditions': profile.healthConditions,
      };
      if (profile.heightCm != null) body['heightCm'] = profile.heightCm;
      if (profile.weightKg != null) body['weightKg'] = profile.weightKg;
      if (profile.bmi != null) body['bmi'] = profile.bmi;
      if (ritualType == RitualType.tawaf) {
        body['currentRadius'] = currentRadius ?? _tawafFallbackRadius;
      }

      final response = await _client
          .post(
            Uri.parse('$_baseUrl/predict'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 4));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return RitualRecommendation.fromJson(
          jsonDecode(response.body) as Map<String, dynamic>,
        );
      }
    } catch (_) {
      // The local ML API is optional during early demos; use deterministic
      // fallback advice so the app remains usable.
    }

    return _fallbackRecommendation(profile, ritualType,
        currentRadius: currentRadius);
  }

  Future<void> saveRecommendation({
    required String uid,
    required RitualRecommendation recommendation,
    required UserProfile profile,
  }) {
    return saveRecommendationPayload(
      buildRecommendationPayload(
        uid: uid,
        recommendation: recommendation,
        profile: profile,
      ),
    );
  }

  Map<String, dynamic> buildRecommendationPayload({
    required String uid,
    required RitualRecommendation recommendation,
    required UserProfile profile,
  }) {
    return {
      'uid': uid,
      'ritualType': recommendation.ritualType.name,
      'inputProfileSnapshot': {
        'age': profile.age,
        'ageGroup': profile.ageGroup,
        'abilityLevel': profile.abilityLevel.name,
        'hasHealthConditions': profile.healthConditions.trim().isNotEmpty,
        'heightCm': profile.heightCm,
        'weightKg': profile.weightKg,
        'bmi': profile.bmi,
      },
      'modelOutput': recommendation.toJson(),
    };
  }

  Future<void> saveRecommendationPayload(Map<String, dynamic> payload) {
    return _firestore.collection('recommendations').add({
      ...payload,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// BMI factor based on CDC BMI categories as a screening reference.
  /// https://www.cdc.gov/bmi/adult-calculator/bmi-categories.html
  static double _bmiFactor(double? bmi) {
    if (bmi == null) return 1.0;
    if (bmi < 18.5) return 0.85;
    if (bmi < 25.0) return 1.0;
    if (bmi < 30.0) return 0.92;
    if (bmi < 35.0) return 0.82;
    return 0.72;
  }

  RitualRecommendation _fallbackRecommendation(
    UserProfile profile,
    RitualType ritualType, {
    double? currentRadius,
  }) {
    final ageFactor = profile.age >= 60
        ? 0.68
        : profile.age >= 45
        ? 0.8
        : 1.0;
    final abilityFactor = switch (profile.abilityLevel) {
      AbilityLevel.low => 0.72,
      AbilityLevel.medium => 0.88,
      AbilityLevel.high => 1.05,
    };
    final healthFactor = profile.healthConditions.trim().isEmpty ? 1.0 : 0.82;
    final bmiFactor = _bmiFactor(profile.bmi);
    final bodyPace = 1.0 * ageFactor * abilityFactor * healthFactor * bmiFactor;

    final double distance;
    final double pace;
    final double time;

    if (ritualType == RitualType.tawaf) {
      final effectiveRadius = (currentRadius ?? _tawafFallbackRadius)
          .clamp(_tawafMinRadius, _tawafMaxRadius);
      distance = 7 * 2 * math.pi * effectiveRadius;
      pace = bodyPace * _tawafPaceMultiplier;
      time = distance / (pace * 60);
    } else {
      distance = _saiFixedDistance;
      pace = bodyPace * _saiPaceMultiplier;
      time = distance / (pace * 60);
    }

    final restEveryMinutes = bodyPace < 0.7 ? 8 : bodyPace < 0.95 ? 10 : 14;
    final label = bodyPace < 0.7
        ? 'Assisted pace'
        : bodyPace < 0.95
        ? 'Balanced pace'
        : 'Active pace';
    final advice = bodyPace < 0.7
        ? 'Move slowly, take frequent short rests, and avoid rushing the ritual.'
        : bodyPace < 0.95
        ? 'Keep a steady rhythm and pause briefly when breathing becomes heavy.'
        : 'Maintain a controlled pace and avoid overexertion even if you feel strong.';

    return RitualRecommendation(
      ritualType: ritualType,
      distanceMinMeters: distance * 0.92,
      distanceMaxMeters: distance * 1.08,
      paceMinMps: pace * 0.88,
      paceMaxMps: pace * 1.12,
      timeMinMinutes: time * 0.9,
      timeMaxMinutes: time * 1.2,
      restEveryMinutes: restEveryMinutes,
      label: label,
      advice: advice,
    );
  }
}
