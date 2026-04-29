import 'package:flutter_test/flutter_test.dart';
import 'package:my_umrah_guide/features/practice/presentation/geofence_provider.dart';
import 'package:my_umrah_guide/features/practice/presentation/guidance/ritual_guidance.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('does not pause tawaf when exiting before any lap progress', () {
    final provider = GeofenceProvider();

    provider.simulateStatus(GeofenceStatus.inside);
    provider.simulateStatus(GeofenceStatus.outside);

    expect(provider.tawafLapCount, 0);
    expect(provider.isTawafPaused, isFalse);
    expect(provider.shouldShowTawafExitPrompt, isFalse);
  });

  test(
    'pauses and blocks lap increments after exiting with saved progress',
    () async {
      final provider = GeofenceProvider();

      provider.simulateStatus(GeofenceStatus.inside);
      provider.incrementTawafLap();
      provider.simulateStatus(GeofenceStatus.outside);

      expect(provider.tawafLapCount, 1);
      expect(provider.isTawafPaused, isTrue);
      expect(provider.shouldShowTawafExitPrompt, isTrue);

      await provider.continueTawafAfterExit();
      provider.incrementTawafLap();

      expect(provider.tawafLapCount, 1);
      expect(provider.isTawafPaused, isTrue);
      expect(provider.shouldShowTawafExitPrompt, isFalse);

      provider.simulateStatus(GeofenceStatus.inside);
      provider.incrementTawafLap();

      expect(provider.tawafLapCount, 2);
      expect(provider.isTawafPaused, isFalse);
    },
  );

  test('end saves tawaf progress for later restore', () async {
    final provider = GeofenceProvider();

    provider.simulateStatus(GeofenceStatus.inside);
    provider.incrementTawafLap();
    provider.simulateStatus(GeofenceStatus.outside);
    await provider.endTawafForLater();

    final restoredProvider = GeofenceProvider();
    await restoredProvider.loadTawafProgress();

    expect(restoredProvider.tawafLapCount, 1);
    expect(restoredProvider.isTawafPaused, isTrue);
    expect(restoredProvider.hasSavedTawafProgress, isTrue);
  });

  test('completion clears saved tawaf recovery progress', () async {
    final provider = GeofenceProvider();

    provider.simulateStatus(GeofenceStatus.inside);
    for (var i = 0; i < 7; i++) {
      provider.incrementTawafLap();
    }

    await Future<void>.delayed(Duration.zero);

    final restoredProvider = GeofenceProvider();
    await restoredProvider.loadTawafProgress();

    expect(provider.tawafLapCount, 7);
    expect(provider.isTawafCompleted, isTrue);
    expect(restoredProvider.tawafLapCount, 0);
    expect(restoredProvider.hasSavedTawafProgress, isFalse);
  });

  test('emits tawaf start guidance once per session', () {
    final provider = GeofenceProvider();

    provider.simulateStatus(GeofenceStatus.inside);

    expect(provider.pendingGuidance?.id, RitualGuidanceCatalog.tawafStart.id);

    provider.consumeGuidance();
    provider.simulateStatus(GeofenceStatus.outside);
    provider.simulateStatus(GeofenceStatus.inside);

    expect(provider.pendingGuidance, isNull);
  });

  test('emits tawaf round and completion guidance', () {
    final provider = GeofenceProvider();

    provider.simulateStatus(GeofenceStatus.inside);
    provider.consumeGuidance();
    provider.incrementTawafLap();

    expect(provider.pendingGuidance?.id, RitualGuidanceCatalog.tawafRound.id);

    provider.consumeGuidance();
    for (var i = 1; i < 7; i++) {
      provider.incrementTawafLap();
    }

    expect(
      provider.pendingGuidance?.id,
      RitualGuidanceCatalog.tawafComplete.id,
    );
  });
}
