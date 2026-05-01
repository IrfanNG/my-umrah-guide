import 'package:flutter_test/flutter_test.dart';
import 'package:my_umrah_guide/features/practice/domain/practice_mode.dart';
import 'package:my_umrah_guide/features/practice/presentation/ritual_progress_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('manual mode unlocks Tawaf and Sa\'i by default', () async {
    final controller = RitualProgressController();

    await controller.load();

    expect(controller.mode, PracticeMode.manual);
    expect(controller.canOpenTawaf, isTrue);
    expect(controller.canOpenSai, isTrue);
  });

  test('location-based mode enforces Niyyah then Tawaf before Sa\'i', () async {
    final controller = RitualProgressController();

    await controller.load();
    await controller.setMode(PracticeMode.locationBased);

    expect(controller.canOpenTawaf, isFalse);
    expect(controller.canOpenSai, isFalse);

    await controller.markNiyyahCompleted();

    expect(controller.canOpenTawaf, isTrue);
    expect(controller.canOpenSai, isFalse);

    await controller.markTawafCompleted();

    expect(controller.canOpenSai, isTrue);
  });

  test('location progress persists and reset clears checkpoints', () async {
    final controller = RitualProgressController();

    await controller.load();
    await controller.setMode(PracticeMode.locationBased);
    await controller.markNiyyahCompleted();
    await controller.markTawafCompleted();

    final restored = RitualProgressController();
    await restored.load();

    expect(restored.mode, PracticeMode.locationBased);
    expect(restored.canOpenTawaf, isTrue);
    expect(restored.canOpenSai, isTrue);

    await restored.resetLocationProgress();

    expect(restored.canOpenTawaf, isFalse);
    expect(restored.canOpenSai, isFalse);
  });
}
