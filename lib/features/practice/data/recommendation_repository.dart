import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;

import '../domain/ritual_recommendation.dart';
import '../domain/user_profile.dart';

class RecommendationRepository {
  RecommendationRepository({
    FirebaseFirestore? firestore,
    http.Client? client,
    String? baseUrl,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _client = client ?? http.Client(),
        _baseUrl = baseUrl ?? 'http://127.0.0.1:8000';

  final FirebaseFirestore _firestore;
  final http.Client _client;
  final String _baseUrl;

  Future<RitualRecommendation> getRecommendation({
    required UserProfile profile,
    required RitualType ritualType,
  }) async {
    try {
      final response = await _client
          .post(
            Uri.parse('$_baseUrl/predict'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'ritualType': ritualType.name,
              'age': profile.age,
              'abilityLevel': profile.abilityLevel.name,
              'healthConditions': profile.healthConditions,
            }),
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

    return _fallbackRecommendation(profile, ritualType);
  }

  Future<void> saveRecommendation({
    required String uid,
    required RitualRecommendation recommendation,
    required UserProfile profile,
  }) {
    return _firestore.collection('recommendations').add({
      'uid': uid,
      'ritualType': recommendation.ritualType.name,
      'inputProfileSnapshot': {
        'age': profile.age,
        'ageGroup': profile.ageGroup,
        'abilityLevel': profile.abilityLevel.name,
        'hasHealthConditions': profile.healthConditions.trim().isNotEmpty,
      },
      'modelOutput': recommendation.toJson(),
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  RitualRecommendation _fallbackRecommendation(
    UserProfile profile,
    RitualType ritualType,
  ) {
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
    final paceCenter = 1.0 * ageFactor * abilityFactor * healthFactor;
    final distance = ritualType == RitualType.tawaf ? 2800.0 : 3100.0;
    final time = distance / (paceCenter * 60);

    return RitualRecommendation(
      ritualType: ritualType,
      distanceMinMeters: distance * 0.92,
      distanceMaxMeters: distance * 1.08,
      paceMinMps: paceCenter * 0.88,
      paceMaxMps: paceCenter * 1.12,
      timeMinMinutes: time * 0.9,
      timeMaxMinutes: time * 1.2,
      restEveryMinutes: paceCenter < 0.7 ? 8 : 12,
      label: paceCenter < 0.7 ? 'Assisted pace' : 'Balanced pace',
      advice: paceCenter < 0.7
          ? 'Move slowly, take frequent short rests, and avoid rushing the ritual.'
          : 'Keep a steady rhythm and pause briefly when breathing becomes heavy.',
    );
  }
}
