import 'package:flutter_test/flutter_test.dart';
import 'package:my_umrah_guide/features/practice/presentation/privacy_consent_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('defaults to no location consent', () async {
    final controller = PrivacyConsentController();

    await controller.load();

    expect(controller.isLoaded, isTrue);
    expect(controller.hasLocationConsent, isFalse);
    expect(
      await PrivacyConsentController.hasAcceptedLocationConsent(),
      isFalse,
    );
  });

  test('acceptance persists location consent', () async {
    final controller = PrivacyConsentController();

    await controller.acceptLocationConsent();

    final restored = PrivacyConsentController();
    await restored.load();

    expect(restored.hasLocationConsent, isTrue);
    expect(await PrivacyConsentController.hasAcceptedLocationConsent(), isTrue);
  });

  test('revocation clears location consent', () async {
    final controller = PrivacyConsentController();

    await controller.acceptLocationConsent();
    await controller.revokeLocationConsent();

    expect(controller.hasLocationConsent, isFalse);
    expect(
      await PrivacyConsentController.hasAcceptedLocationConsent(),
      isFalse,
    );
  });
}
