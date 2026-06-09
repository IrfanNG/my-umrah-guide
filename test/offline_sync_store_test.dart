import 'package:flutter_test/flutter_test.dart';
import 'package:my_umrah_guide/features/practice/data/offline_sync_store.dart';
import 'package:my_umrah_guide/features/practice/domain/ritual_recommendation.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('stores and restores cached recommendation by cache key', () async {
    final store = OfflineSyncStore();
    const recommendation = RitualRecommendation(
      ritualType: RitualType.tawaf,
      distanceMinMeters: 2500,
      distanceMaxMeters: 3000,
      paceMinMps: 0.8,
      paceMaxMps: 1.1,
      timeMinMinutes: 45,
      timeMaxMinutes: 60,
      restEveryMinutes: 12,
      label: 'Balanced pace',
      advice: 'Keep a steady rhythm.',
    );

    await store.writeRecommendation(
      cacheKey: 'user-1|tawaf|30|medium|',
      recommendation: recommendation,
    );

    final restored = await store.readRecommendation('user-1|tawaf|30|medium|');

    expect(restored, isNotNull);
    expect(restored!.recommendation.ritualType, RitualType.tawaf);
    expect(restored.recommendation.distanceMinMeters, 2500);
    expect(restored.recommendation.label, 'Balanced pace');
  });

  test('queues pending writes and replaces duplicate queue ids', () async {
    final store = OfflineSyncStore();

    await store.enqueueWrite(
      PendingSyncWrite(
        id: 'session|user-1|tawaf',
        type: PendingSyncType.ritualSession,
        payload: const {'ritualType': 'tawaf', 'durationMinutes': 40},
        queuedAt: DateTime(2026),
      ),
    );
    await store.enqueueWrite(
      PendingSyncWrite(
        id: 'session|user-1|tawaf',
        type: PendingSyncType.ritualSession,
        payload: const {'ritualType': 'tawaf', 'durationMinutes': 45},
        queuedAt: DateTime(2026, 1, 2),
      ),
    );

    final pending = await store.readPendingWrites();

    expect(pending, hasLength(1));
    expect(pending.single.payload['durationMinutes'], 45);
    expect(await store.pendingWriteCount(), 1);
  });

  test('keeps separate queue entries for same uid+ritual with different timestamps', () async {
    final store = OfflineSyncStore();

    await store.enqueueWrite(
      PendingSyncWrite(
        id: 'session|user-1|tawaf|2026-06-09T10:00:00.000',
        type: PendingSyncType.ritualSession,
        payload: const {'ritualType': 'tawaf', 'durationMinutes': 40},
        queuedAt: DateTime(2026, 6, 9, 10, 0, 0),
      ),
    );
    await store.enqueueWrite(
      PendingSyncWrite(
        id: 'session|user-1|tawaf|2026-06-09T11:00:00.000',
        type: PendingSyncType.ritualSession,
        payload: const {'ritualType': 'tawaf', 'durationMinutes': 45},
        queuedAt: DateTime(2026, 6, 9, 11, 0, 0),
      ),
    );

    final pending = await store.readPendingWrites();

    expect(pending, hasLength(2));
    expect(await store.pendingWriteCount(), 2);
  });

  test('removes synced pending writes by id', () async {
    final store = OfflineSyncStore();
    await store.enqueueWrite(
      PendingSyncWrite(
        id: 'recommendation|user-1|tawaf',
        type: PendingSyncType.recommendation,
        payload: const {'uid': 'user-1'},
        queuedAt: DateTime(2026),
      ),
    );

    await store.removePendingWrite('recommendation|user-1|tawaf');

    expect(await store.readPendingWrites(), isEmpty);
  });

  test('serializes ritual session logs for queued analytics sync', () {
    final now = DateTime(2026, 6, 9, 10, 0, 0);
    final log = RitualSessionLog(
      uid: 'user-1',
      ritualType: RitualType.sai,
      ageGroup: '30-44',
      abilityLevel: 'medium',
      distanceMeters: 3100,
      averagePaceMps: 0.9,
      durationMinutes: 58,
      recommendationSnapshot: const {'label': 'Balanced pace'},
      startedAt: now.subtract(const Duration(minutes: 58)),
      completedAt: now,
    );

    final restored = RitualSessionLog.fromJson(log.toJson());

    expect(restored.uid, 'user-1');
    expect(restored.ritualType, RitualType.sai);
    expect(restored.recommendationSnapshot['label'], 'Balanced pace');
    expect(restored.startedAt, log.startedAt);
    expect(restored.completedAt, log.completedAt);
  });
}
