import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/app/backend_target.dart';
import 'package:nestprep/features/observability/crash_reporting.dart';

void main() {
  group('whether a report leaves the device', () {
    test('never in a test or debug build, whatever the backend', () {
      // `flutter test` is not a release build, so both answers are false —
      // which is the rule that matters: development noise never reaches the
      // dashboard (observability ADR-0001).
      expect(CrashReporting.shouldSend(BackendTarget.emulator), isFalse);
      expect(CrashReporting.shouldSend(BackendTarget.cloud), isFalse);
    });

    test('never when the build talks to the emulator', () {
      // The emulator target is excluded on its own, so a release build pointed
      // at the emulator suite still sends nothing.
      expect(CrashReporting.shouldSend(BackendTarget.emulator), isFalse);
    });
  });

  group('the forced crash', () {
    test('throws, so the verification run has something to report', () {
      expect(CrashReporting.forceACrashForTesting, throwsStateError);
    });
  });
}
