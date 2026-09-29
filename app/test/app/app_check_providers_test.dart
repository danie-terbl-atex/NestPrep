import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/app/app_check_providers.dart';
import 'package:nestprep/app/backend_target.dart';
import 'package:nestprep/app/firebase_bootstrap.dart';

/// Which App Check attestation a build asks for (foundation ADR-0016).
///
/// `kReleaseMode` folds to false under `flutter test`, so the release branch —
/// the only one a store build takes — is reachable only through `choose`.
void main() {
  group('the plan', () {
    test('an emulator build asks for nothing, release or not', () {
      // App Check has no emulator; a service is redirected there or unused.
      for (final isReleaseBuild in [false, true]) {
        final plan = AppCheckPlan.choose(
          target: BackendTarget.emulator,
          isReleaseBuild: isReleaseBuild,
        );
        expect(plan, AppCheckPlan.off);
        expect(plan.android, isNull);
        expect(plan.apple, isNull);
      }
    });

    test('a debug build against the cloud uses the debug providers', () {
      final plan = AppCheckPlan.choose(
        target: BackendTarget.cloud,
        isReleaseBuild: false,
      );
      expect(plan, AppCheckPlan.debug);
      expect(plan.android, isA<AndroidDebugProvider>());
      expect(plan.apple, isA<AppleDebugProvider>());
    });

    test('a release build against the cloud attests with the platform', () {
      final plan = AppCheckPlan.choose(
        target: BackendTarget.cloud,
        isReleaseBuild: true,
      );
      expect(plan, AppCheckPlan.attested);
      expect(plan.android, isA<AndroidPlayIntegrityProvider>());
      // App Attest, falling back to DeviceCheck on a phone that cannot.
      expect(plan.apple, isA<AppleAppAttestWithDeviceCheckFallbackProvider>());
    });

    test('a test run is never a release build', () {
      expect(
        AppCheckPlan.forThisBuild(BackendTarget.cloud),
        AppCheckPlan.debug,
      );
    });
  });

  test('activating with the plan off touches no Firebase at all', () async {
    // No `Firebase.initializeApp` has run in this test, so reaching
    // `FirebaseAppCheck.instance` would throw — completing proves it did not.
    await expectLater(activateAppCheck(AppCheckPlan.off), completes);
  });

  test('an activation that fails is logged and the app still starts', () async {
    // With no Firebase app, activation throws inside the best-effort run;
    // nothing enforces App Check yet, so startup must carry on (ENG-10).
    await expectLater(activateAppCheck(AppCheckPlan.debug), completes);
  });
}
