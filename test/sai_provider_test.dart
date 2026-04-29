import 'package:flutter_test/flutter_test.dart';
import 'package:my_umrah_guide/features/practice/presentation/guidance/ritual_guidance.dart';
import 'package:my_umrah_guide/features/practice/presentation/sai_provider.dart';

void main() {
  test('requires Safa and Marwa before counting one Sa\'i lap', () {
    final provider = SaiProvider();

    provider.simulateReachHill();

    expect(provider.saiLapCount, 0);
    expect(provider.hasReachedMarwaForCurrentLap, isTrue);
    expect(provider.hasReachedSafaForCurrentLap, isFalse);
    expect(provider.currentLapProgressLabel, contains('Marwa reached'));
    expect(provider.pendingGuidance?.id, RitualGuidanceCatalog.saiMarwa.id);

    provider.consumeGuidance();
    provider.simulateReachHill();

    expect(provider.saiLapCount, 1);
    expect(provider.hasReachedMarwaForCurrentLap, isFalse);
    expect(provider.hasReachedSafaForCurrentLap, isFalse);
    expect(provider.currentLapProgressLabel, contains('reach Safa and Marwa'));
    expect(provider.pendingGuidance?.id, RitualGuidanceCatalog.saiSafa.id);
  });

  test('emits Sa\'i hill guidance once per session per hill', () {
    final provider = SaiProvider();

    provider.simulateReachHill();

    expect(provider.pendingGuidance?.id, RitualGuidanceCatalog.saiMarwa.id);

    provider.consumeGuidance();
    provider.simulateReachHill();

    expect(provider.pendingGuidance?.id, RitualGuidanceCatalog.saiSafa.id);

    provider.consumeGuidance();
    provider.simulateReachHill();

    expect(provider.saiLapCount, 1);
    expect(provider.pendingGuidance, isNull);
  });

  test(
    'emits Sa\'i completion guidance when seven full pairs are completed',
    () {
      final provider = SaiProvider();

      for (var i = 0; i < 14; i++) {
        provider.simulateReachHill();
        if (i < 13) {
          provider.consumeGuidance();
        }
      }

      expect(provider.saiLapCount, 7);
      expect(
        provider.pendingGuidance?.id,
        RitualGuidanceCatalog.saiComplete.id,
      );
      expect(provider.currentLapProgressLabel, 'Sa\'i completed');
    },
  );

  test('resetSai clears pair progress and target state', () {
    final provider = SaiProvider();

    provider.simulateReachHill();
    provider.resetSai();

    expect(provider.saiLapCount, 0);
    expect(provider.hasReachedMarwaForCurrentLap, isFalse);
    expect(provider.hasReachedSafaForCurrentLap, isFalse);
    expect(provider.nextTarget, HillTarget.marwa);
    expect(provider.currentLapProgressLabel, contains('reach Safa and Marwa'));
  });
}
