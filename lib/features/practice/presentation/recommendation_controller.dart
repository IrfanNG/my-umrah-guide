import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../data/analytics_repository.dart';
import '../data/profile_repository.dart';
import '../data/recommendation_repository.dart';
import '../domain/ritual_recommendation.dart';
import '../domain/user_profile.dart';

class RecommendationController with ChangeNotifier {
  RecommendationController({
    RecommendationRepository? recommendationRepository,
    ProfileRepository? profileRepository,
    AnalyticsRepository? analyticsRepository,
    FirebaseAuth? auth,
  })  : _recommendationRepository =
            recommendationRepository ?? RecommendationRepository(),
        _profileRepository = profileRepository ?? ProfileRepository(),
        _analyticsRepository = analyticsRepository ?? AnalyticsRepository(),
        _auth = auth ?? FirebaseAuth.instance;

  final RecommendationRepository _recommendationRepository;
  final ProfileRepository _profileRepository;
  final AnalyticsRepository _analyticsRepository;
  final FirebaseAuth _auth;

  final Map<RitualType, RitualRecommendation> _recommendations = {};
  final Map<RitualType, String> _recommendationKeys = {};
  final Map<RitualType, UserProfile> _profiles = {};
  final Set<RitualType> _loadingRituals = {};
  final Set<RitualType> _loggedCompletions = {};
  String? _errorMessage;

  String? get errorMessage => _errorMessage;

  RitualRecommendation? recommendationFor(RitualType ritualType) {
    return _recommendations[ritualType];
  }

  UserProfile? profileFor(RitualType ritualType) {
    return _profiles[ritualType];
  }

  bool isLoading(RitualType ritualType) => _loadingRituals.contains(ritualType);

  Future<void> loadRecommendation(RitualType ritualType) async {
    if (isLoading(ritualType)) return;
    final user = _auth.currentUser;
    if (user == null) return;

    final profile = await _profileRepository.getProfile(user.uid);
    if (profile == null || !profile.isComplete) return;

    final cacheKey = _cacheKey(user.uid, profile, ritualType);
    if (_recommendationKeys[ritualType] == cacheKey &&
        _recommendations.containsKey(ritualType)) {
      return;
    }

    _loadingRituals.add(ritualType);
    _errorMessage = null;
    notifyListeners();

    try {
      final recommendation = await _recommendationRepository.getRecommendation(
        profile: profile,
        ritualType: ritualType,
      );
      _recommendations[ritualType] = recommendation;
      _recommendationKeys[ritualType] = cacheKey;
      _profiles[ritualType] = profile;
      await _recommendationRepository.saveRecommendation(
        uid: user.uid,
        recommendation: recommendation,
        profile: profile,
      );
    } catch (_) {
      _errorMessage = 'Unable to load recommendation right now.';
    } finally {
      _loadingRituals.remove(ritualType);
      notifyListeners();
    }
  }

  void refreshRecommendation(RitualType ritualType) {
    _recommendationKeys.remove(ritualType);
    _recommendations.remove(ritualType);
    _profiles.remove(ritualType);
    notifyListeners();
    loadRecommendation(ritualType);
  }

  Future<void> logCompletionOnce({
    required RitualType ritualType,
    required int completedUnits,
  }) async {
    if (completedUnits < 7 || _loggedCompletions.contains(ritualType)) return;
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      final profile = await _profileRepository.getProfile(user.uid);
      final recommendation = _recommendations[ritualType];
      if (profile == null || recommendation == null) return;
      final distance = (recommendation.distanceMinMeters +
              recommendation.distanceMaxMeters) /
          2;
      final pace =
          (recommendation.paceMinMps + recommendation.paceMaxMps) / 2;
      final duration =
          (recommendation.timeMinMinutes + recommendation.timeMaxMinutes) / 2;
      await _analyticsRepository.logSession(
        RitualSessionLog(
          uid: user.uid,
          ritualType: ritualType,
          ageGroup: profile.ageGroup,
          abilityLevel: profile.abilityLevel.name,
          distanceMeters: distance,
          averagePaceMps: pace,
          durationMinutes: duration,
          recommendationSnapshot: recommendation.toJson(),
        ),
      );
      _loggedCompletions.add(ritualType);
    } catch (_) {
      _errorMessage = 'Session analytics could not be saved.';
      notifyListeners();
    }
  }

  String _cacheKey(
    String uid,
    UserProfile profile,
    RitualType ritualType,
  ) {
    return [
      uid,
      ritualType.name,
      profile.age.toString(),
      profile.abilityLevel.name,
      profile.healthConditions.trim().toLowerCase(),
    ].join('|');
  }
}
