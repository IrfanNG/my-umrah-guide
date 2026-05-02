import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../data/analytics_repository.dart';
import '../data/offline_sync_store.dart';
import '../data/profile_repository.dart';
import '../data/recommendation_repository.dart';
import '../domain/ritual_recommendation.dart';
import '../domain/user_profile.dart';

class RecommendationController with ChangeNotifier {
  RecommendationController({
    RecommendationRepository? recommendationRepository,
    ProfileRepository? profileRepository,
    AnalyticsRepository? analyticsRepository,
    OfflineSyncStore? offlineSyncStore,
    FirebaseAuth? auth,
  }) : _recommendationRepository =
           recommendationRepository ?? RecommendationRepository(),
       _profileRepository = profileRepository ?? ProfileRepository(),
       _analyticsRepository = analyticsRepository ?? AnalyticsRepository(),
       _offlineSyncStore = offlineSyncStore ?? OfflineSyncStore(),
       _auth = auth ?? FirebaseAuth.instance;

  final RecommendationRepository _recommendationRepository;
  final ProfileRepository _profileRepository;
  final AnalyticsRepository _analyticsRepository;
  final OfflineSyncStore _offlineSyncStore;
  final FirebaseAuth _auth;

  final Map<RitualType, RitualRecommendation> _recommendations = {};
  final Map<RitualType, String> _recommendationKeys = {};
  final Map<RitualType, UserProfile> _profiles = {};
  final Set<RitualType> _loadingRituals = {};
  final Set<RitualType> _loggedCompletions = {};
  final Set<RitualType> _cachedRecommendations = {};
  int _pendingSyncCount = 0;
  String? _errorMessage;
  String? _syncMessage;

  String? get errorMessage => _errorMessage;
  String? get syncMessage => _syncMessage;
  int get pendingSyncCount => _pendingSyncCount;
  bool get hasPendingSync => _pendingSyncCount > 0;

  RitualRecommendation? recommendationFor(RitualType ritualType) {
    return _recommendations[ritualType];
  }

  UserProfile? profileFor(RitualType ritualType) {
    return _profiles[ritualType];
  }

  bool isLoading(RitualType ritualType) => _loadingRituals.contains(ritualType);
  bool isCached(RitualType ritualType) {
    return _cachedRecommendations.contains(ritualType);
  }

  Future<void> loadRecommendation(RitualType ritualType) async {
    if (isLoading(ritualType)) return;
    final user = _auth.currentUser;
    if (user == null) return;

    final profile = await _profileRepository.getProfile(user.uid);
    if (profile == null || !profile.isComplete) return;

    final cacheKey = _cacheKey(user.uid, profile, ritualType);
    if (_recommendationKeys[ritualType] == cacheKey &&
        _recommendations.containsKey(ritualType) &&
        !isCached(ritualType)) {
      await syncPendingWrites();
      return;
    }

    final cached = await _offlineSyncStore.readRecommendation(cacheKey);
    if (cached != null) {
      _recommendations[ritualType] = cached.recommendation;
      _recommendationKeys[ritualType] = cacheKey;
      _profiles[ritualType] = profile;
      _cachedRecommendations.add(ritualType);
      _syncMessage = 'Showing cached recommendation while refreshing.';
      await _refreshPendingSyncCount();
      notifyListeners();
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
      _cachedRecommendations.remove(ritualType);
      await _offlineSyncStore.writeRecommendation(
        cacheKey: cacheKey,
        recommendation: recommendation,
      );
      await _saveRecommendationOrQueue(
        uid: user.uid,
        profile: profile,
        recommendation: recommendation,
        cacheKey: cacheKey,
      );
      await syncPendingWrites(notify: false);
    } catch (_) {
      if (!_recommendations.containsKey(ritualType)) {
        _errorMessage = 'Unable to load recommendation right now.';
      }
    } finally {
      _loadingRituals.remove(ritualType);
      await _refreshPendingSyncCount();
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
      final distance =
          (recommendation.distanceMinMeters +
              recommendation.distanceMaxMeters) /
          2;
      final pace = (recommendation.paceMinMps + recommendation.paceMaxMps) / 2;
      final duration =
          (recommendation.timeMinMinutes + recommendation.timeMaxMinutes) / 2;
      final log = RitualSessionLog(
        uid: user.uid,
        ritualType: ritualType,
        ageGroup: profile.ageGroup,
        abilityLevel: profile.abilityLevel.name,
        distanceMeters: distance,
        averagePaceMps: pace,
        durationMinutes: duration,
        recommendationSnapshot: recommendation.toJson(),
      );
      await _logSessionOrQueue(log);
      await syncPendingWrites(notify: false);
      _loggedCompletions.add(ritualType);
    } catch (_) {
      _errorMessage = 'Session analytics could not be saved.';
    } finally {
      await _refreshPendingSyncCount();
      notifyListeners();
    }
  }

  Future<void> syncPendingWrites({bool notify = true}) async {
    final pending = await _offlineSyncStore.readPendingWrites();
    if (pending.isEmpty) {
      _pendingSyncCount = 0;
      if (_syncMessage == 'Pending data will sync when online.') {
        _syncMessage = null;
      }
      if (notify) notifyListeners();
      return;
    }

    for (final write in pending) {
      try {
        switch (write.type) {
          case PendingSyncType.recommendation:
            await _recommendationRepository.saveRecommendationPayload(
              write.payload,
            );
          case PendingSyncType.ritualSession:
            await _analyticsRepository.logSession(
              RitualSessionLog.fromJson(write.payload),
            );
        }
        await _offlineSyncStore.removePendingWrite(write.id);
      } catch (_) {
        break;
      }
    }

    await _refreshPendingSyncCount();
    if (_pendingSyncCount == 0 &&
        _syncMessage == 'Pending data will sync when online.') {
      _syncMessage = 'Pending data synced.';
    }
    if (notify) notifyListeners();
  }

  Future<void> _saveRecommendationOrQueue({
    required String uid,
    required UserProfile profile,
    required RitualRecommendation recommendation,
    required String cacheKey,
  }) async {
    final payload = _recommendationRepository.buildRecommendationPayload(
      uid: uid,
      recommendation: recommendation,
      profile: profile,
    );
    try {
      await _recommendationRepository.saveRecommendationPayload(payload);
      _syncMessage = null;
    } catch (_) {
      await _offlineSyncStore.enqueueWrite(
        PendingSyncWrite(
          id: 'recommendation|$cacheKey',
          type: PendingSyncType.recommendation,
          payload: payload,
          queuedAt: DateTime.now(),
        ),
      );
      _syncMessage = 'Pending data will sync when online.';
    }
  }

  Future<void> _logSessionOrQueue(RitualSessionLog log) async {
    try {
      await _analyticsRepository.logSession(log);
      _syncMessage = null;
    } catch (_) {
      await _offlineSyncStore.enqueueWrite(
        PendingSyncWrite(
          id: 'session|${log.uid}|${log.ritualType.name}',
          type: PendingSyncType.ritualSession,
          payload: log.toJson(),
          queuedAt: DateTime.now(),
        ),
      );
      _syncMessage = 'Pending data will sync when online.';
    }
  }

  Future<void> _refreshPendingSyncCount() async {
    _pendingSyncCount = await _offlineSyncStore.pendingWriteCount();
  }

  String _cacheKey(String uid, UserProfile profile, RitualType ritualType) {
    return [
      uid,
      ritualType.name,
      profile.age.toString(),
      profile.abilityLevel.name,
      profile.healthConditions.trim().toLowerCase(),
    ].join('|');
  }
}
