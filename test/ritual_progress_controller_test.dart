import 'package:flutter_test/flutter_test.dart';
import 'package:my_umrah_guide/features/practice/domain/practice_mode.dart';
import 'package:my_umrah_guide/features/practice/presentation/guest_session_controller.dart';
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

  test('guest progress stays isolated from user progress', () async {
    final guestSession = GuestSessionController();
    await guestSession.load();
    await guestSession.enterGuestMode();

    final guestController = RitualProgressController(
      guestSessionController: guestSession,
    );
    await guestController.load();
    await guestController.setMode(PracticeMode.locationBased);
    await guestController.markNiyyahCompleted();

    final userSession = GuestSessionController();
    await userSession.load();
    await userSession.exitGuestMode();

    final userController = RitualProgressController(
      guestSessionController: userSession,
    );
    await userController.load();

    expect(userController.mode, PracticeMode.manual);
    expect(userController.canOpenTawaf, isTrue);
    expect(userController.canOpenSai, isTrue);
  });
}
