import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter/foundation.dart';

import 'backend_target.dart';

/// Which App Check attestation this build asks for (foundation ADR-0016).
///
/// App Check has no emulator, so an emulator build turns it off rather than
/// talk to the real attestation service — the root rule that a Firebase
/// service is redirected to the suite or not used at all. A debug or profile
/// build against the cloud uses the debug provider, whose token is registered
/// by hand in the console; only a release build against the cloud proves
/// itself with Play Integrity or App Attest.
enum AppCheckPlan {
  off,
  debug,
  attested;

  /// The rule, with the build mode passed in. `kReleaseMode` is a
  /// compile-time constant, so a test that read it could never reach
  /// [attested] — the same reason `CrashReporting.shouldSendFrom` exists.
  static AppCheckPlan choose({
    required BackendTarget target,
    required bool isReleaseBuild,
  }) => switch ((target, isReleaseBuild)) {
    (BackendTarget.emulator, _) => AppCheckPlan.off,
    (BackendTarget.cloud, false) => AppCheckPlan.debug,
    (BackendTarget.cloud, true) => AppCheckPlan.attested,
  };

  static AppCheckPlan forThisBuild(BackendTarget target) =>
      choose(target: target, isReleaseBuild: kReleaseMode);

  /// The Android provider, or null when App Check stays off.
  AndroidAppCheckProvider? get android => switch (this) {
    AppCheckPlan.off => null,
    AppCheckPlan.debug => const AndroidDebugProvider(),
    AppCheckPlan.attested => const AndroidPlayIntegrityProvider(),
  };

  /// The Apple provider, or null when App Check stays off. App Attest needs
  /// iOS 14 and a real device; DeviceCheck covers the rest.
  AppleAppCheckProvider? get apple => switch (this) {
    AppCheckPlan.off => null,
    AppCheckPlan.debug => const AppleDebugProvider(),
    AppCheckPlan.attested =>
      const AppleAppAttestWithDeviceCheckFallbackProvider(),
  };
}
