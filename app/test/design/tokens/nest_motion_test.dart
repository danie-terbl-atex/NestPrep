import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/design/nest_kit.dart';

void main() {
  testWidgets('durations are zero when the platform reduces motion', (
    tester,
  ) async {
    late NestMotion motion;
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(disableAnimations: true),
        child: Builder(
          builder: (context) {
            motion = NestMotion.of(context);
            return const SizedBox();
          },
        ),
      ),
    );
    expect(motion.isReduced, isTrue);
    expect(motion.quick, Duration.zero);
    expect(motion.standard, Duration.zero);
    expect(motion.slow, Duration.zero);
  });

  testWidgets('durations are set when motion is allowed', (tester) async {
    late NestMotion motion;
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(),
        child: Builder(
          builder: (context) {
            motion = NestMotion.of(context);
            return const SizedBox();
          },
        ),
      ),
    );
    expect(motion.isReduced, isFalse);
    expect(motion.standard, greaterThan(motion.quick));
    expect(motion.slow, greaterThan(motion.standard));
  });

  test('both themes install the extension and derive Material from it', () {
    for (final nest in [NestTheme.light(), NestTheme.dark()]) {
      final data = nestThemeData(nest);
      expect(data.extension<NestTheme>(), same(nest));
      expect(data.brightness, nest.brightness);
      expect(data.colorScheme.primary, nest.colors.accent);
      expect(data.scaffoldBackgroundColor, nest.colors.canvas);
    }
  });
}
