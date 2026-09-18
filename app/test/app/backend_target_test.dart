import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/app/backend_target.dart';

/// Which backend a build talks to, and the parse that decides it.
///
/// `fromEnvironment` reads a `String.fromEnvironment` constant, so under
/// `flutter test` it is always `'emulator'` and the `'cloud'` branch is
/// unreachable — which means the branch every real cloud build takes had never
/// been executed by anything, and neither had the refusal. A typo in either
/// shows up as an app that throws on launch, on the one build nobody runs
/// locally. So the parse is its own function and this exercises all three ways
/// out of it.
void main() {
  test('emulator is the default, so a clone needs no cloud project', () {
    expect(BackendTarget.fromEnvironment(), BackendTarget.emulator);
  });

  group('the parse', () {
    test('reads emulator', () {
      expect(BackendTarget.fromName('emulator'), BackendTarget.emulator);
    });

    test('reads cloud — the branch a real cloud build takes', () {
      expect(BackendTarget.fromName('cloud'), BackendTarget.cloud);
    });

    test('refuses anything else rather than guessing a backend', () {
      // Guessing here would point a build at the wrong Firebase project, which
      // is the one mistake that writes a family's data somewhere unintended.
      expect(
        () => BackendTarget.fromName('staging'),
        throwsA(isA<ArgumentError>()),
      );
    });

    test(
      'names the define and the bad value, so the message is actionable',
      () {
        // The person reading this is looking at a crash on launch with no other
        // clue about which flag was wrong.
        expect(
          () => BackendTarget.fromName('Cloud'),
          throwsA(
            isA<ArgumentError>()
                .having((e) => e.name, 'name', BackendTarget.defineName)
                .having((e) => e.invalidValue, 'invalidValue', 'Cloud'),
          ),
        );
      },
    );

    test('is case-sensitive and does not trim, because a define is exact', () {
      expect(() => BackendTarget.fromName('CLOUD'), throwsArgumentError);
      expect(() => BackendTarget.fromName(' cloud'), throwsArgumentError);
      expect(() => BackendTarget.fromName(''), throwsArgumentError);
    });
  });
}
