import 'package:flutter_test/flutter_test.dart';
import 'package:my_umrah_guide/features/practice/presentation/guest_session_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('guest mode persists across controller instances', () async {
    final controller = GuestSessionController();

    await controller.load();
    expect(controller.isGuestMode, isFalse);

    await controller.enterGuestMode();
    expect(controller.isGuestMode, isTrue);

    final restored = GuestSessionController();
    await restored.load();

    expect(restored.isGuestMode, isTrue);
  });

  test('guest mode can be cleared after sign out', () async {
    final controller = GuestSessionController();

    await controller.load();
    await controller.enterGuestMode();
    await controller.exitGuestMode();

    final restored = GuestSessionController();
    await restored.load();

    expect(restored.isGuestMode, isFalse);
  });
}
