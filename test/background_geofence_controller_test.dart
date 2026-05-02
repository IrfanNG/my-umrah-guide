import 'package:flutter_test/flutter_test.dart';
import 'package:my_umrah_guide/features/practice/presentation/background_geofence_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('defaults to disabled background monitoring', () async {
    final controller = BackgroundGeofenceController(
      readinessProbe: () async => BackgroundGeofenceReadiness.ready,
    );

    await controller.load();

    expect(controller.isLoaded, isTrue);
    expect(controller.isEnabled, isFalse);
    expect(controller.readiness, BackgroundGeofenceReadiness.disabled);
    expect(controller.canUseBackgroundMonitoring, isFalse);
  });

  test('enabled preference persists across controller instances', () async {
    final controller = BackgroundGeofenceController();

    await controller.load();
    await controller.setEnabled(true);

    final restored = BackgroundGeofenceController(
      readinessProbe: () async => BackgroundGeofenceReadiness.ready,
    );
    await restored.load();

    expect(restored.isEnabled, isTrue);
  });

  test('disabled state reports foreground-only tracking message', () async {
    final controller = BackgroundGeofenceController();

    await controller.load();
    await controller.setEnabled(false);

    expect(controller.statusMessage, contains('practice screens are open'));
  });
}
