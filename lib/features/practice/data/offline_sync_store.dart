import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/ritual_recommendation.dart';

enum PendingSyncType {
  recommendation,
  ritualSession;

  static PendingSyncType fromValue(String? value) {
    return PendingSyncType.values.firstWhere(
      (type) => type.name == value,
      orElse: () => PendingSyncType.recommendation,
    );
  }
}

class CachedRecommendation {
  const CachedRecommendation({
    required this.cacheKey,
    required this.recommendation,
    required this.cachedAt,
  });

  final String cacheKey;
  final RitualRecommendation recommendation;
  final DateTime cachedAt;

  Map<String, dynamic> toJson() {
    return {
      'cacheKey': cacheKey,
      'recommendation': recommendation.toJson(),
      'cachedAt': cachedAt.toIso8601String(),
    };
  }

  factory CachedRecommendation.fromJson(Map<String, dynamic> json) {
    return CachedRecommendation(
      cacheKey: json['cacheKey'] as String? ?? '',
      recommendation: RitualRecommendation.fromJson(
        Map<String, dynamic>.from(
          json['recommendation'] as Map? ?? <String, dynamic>{},
        ),
      ),
      cachedAt:
          DateTime.tryParse(json['cachedAt'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }
}

class PendingSyncWrite {
  const PendingSyncWrite({
    required this.id,
    required this.type,
    required this.payload,
    required this.queuedAt,
  });

  final String id;
  final PendingSyncType type;
  final Map<String, dynamic> payload;
  final DateTime queuedAt;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'payload': payload,
      'queuedAt': queuedAt.toIso8601String(),
    };
  }

  factory PendingSyncWrite.fromJson(Map<String, dynamic> json) {
    return PendingSyncWrite(
      id: json['id'] as String? ?? '',
      type: PendingSyncType.fromValue(json['type'] as String?),
      payload: Map<String, dynamic>.from(
        json['payload'] as Map? ?? <String, dynamic>{},
      ),
      queuedAt:
          DateTime.tryParse(json['queuedAt'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }
}

class OfflineSyncStore {
  static const String _recommendationCacheKey =
      'phase3_recommendation_cache_v1';
  static const String _pendingWritesKey = 'phase3_pending_sync_writes_v1';
  static const int _maxPendingWrites = 30;

  Future<CachedRecommendation?> readRecommendation(String cacheKey) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_recommendationCacheKey);
    if (raw == null || raw.isEmpty) return null;

    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    final entry = decoded[cacheKey] as Map?;
    if (entry == null) return null;

    return CachedRecommendation.fromJson(Map<String, dynamic>.from(entry));
  }

  Future<void> writeRecommendation({
    required String cacheKey,
    required RitualRecommendation recommendation,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_recommendationCacheKey);
    final decoded = raw == null || raw.isEmpty
        ? <String, dynamic>{}
        : Map<String, dynamic>.from(jsonDecode(raw) as Map);

    decoded[cacheKey] = CachedRecommendation(
      cacheKey: cacheKey,
      recommendation: recommendation,
      cachedAt: DateTime.now(),
    ).toJson();

    await prefs.setString(_recommendationCacheKey, jsonEncode(decoded));
  }

  Future<List<PendingSyncWrite>> readPendingWrites() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_pendingWritesKey);
    if (raw == null || raw.isEmpty) return <PendingSyncWrite>[];

    final decoded = jsonDecode(raw) as List;
    return decoded
        .map(
          (item) =>
              PendingSyncWrite.fromJson(Map<String, dynamic>.from(item as Map)),
        )
        .where((write) => write.id.isNotEmpty)
        .toList();
  }

  Future<void> enqueueWrite(PendingSyncWrite write) async {
    final pending = await readPendingWrites();
    final withoutDuplicate =
        pending.where((existing) => existing.id != write.id).toList()
          ..add(write);
    final bounded = withoutDuplicate.length > _maxPendingWrites
        ? withoutDuplicate.sublist(withoutDuplicate.length - _maxPendingWrites)
        : withoutDuplicate;
    await _writePendingWrites(bounded);
  }

  Future<void> removePendingWrite(String id) async {
    final pending = await readPendingWrites();
    await _writePendingWrites(
      pending.where((write) => write.id != id).toList(),
    );
  }

  Future<int> pendingWriteCount() async {
    final pending = await readPendingWrites();
    return pending.length;
  }

  Future<void> _writePendingWrites(List<PendingSyncWrite> pending) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _pendingWritesKey,
      jsonEncode(pending.map((write) => write.toJson()).toList()),
    );
  }
}
