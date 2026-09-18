import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/app/backend_target.dart';
import 'package:nestprep/features/observability/crash_reporting.dart';

void main() {
  group('whether a report leaves the device', () {
    test('never from a test or debug build, whatever the backend', () {
      // True as written, and worth keeping — but it proves only half of the
      // rule. `kReleaseMode` is a compile-time constant, so under `flutter
      // test` the expression folds to `false` before the target is read, and
      // this would pass with the target condition deleted.
      expect(CrashReporting.shouldSend(BackendTarget.emulator), isFalse);
      expect(CrashReporting.shouldSend(BackendTarget.cloud), isFalse);
    });

    // Which is why the rule takes the build mode as an argument. All four
    // answers, and only one of them is yes (observability ADR-0001).
    test('only a release build pointed at the cloud sends anything', () {
      expect(
        CrashReporting.shouldSendFrom(
          isReleaseBuild: true,
          target: BackendTarget.cloud,
        ),
        isTrue,
      );
    });

    test('a release build on the emulator suite sends nothing', () {
      // The emulator target is excluded on its own, so pointing a release build
      // at the local suite does not start filling the dashboard.
      expect(
        CrashReporting.shouldSendFrom(
          isReleaseBuild: true,
          target: BackendTarget.emulator,
        ),
        isFalse,
      );
    });

    test('a debug build sends nothing, even against the cloud', () {
      // This is the one a hand-driven cloud run would otherwise break: the
      // backend is real, the build is not.
      expect(
        CrashReporting.shouldSendFrom(
          isReleaseBuild: false,
          target: BackendTarget.cloud,
        ),
        isFalse,
      );
    });

    test('a debug build on the emulator sends nothing', () {
      expect(
        CrashReporting.shouldSendFrom(
          isReleaseBuild: false,
          target: BackendTarget.emulator,
        ),
        isFalse,
      );
    });
  });

  group('the forced crash', () {
    test('throws, so the verification run has something to report', () {
      expect(CrashReporting.forceACrashForTesting, throwsStateError);
    });
  });
}
