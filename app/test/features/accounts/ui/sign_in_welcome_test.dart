import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/design/nest_kit.dart';
import 'package:nestprep/features/accounts/ui/sign_in_welcome.dart';

import '../../../support/pump_kit.dart';

/// The welcome's three rings turn different ways at different speeds
/// (design-system ADR-0006). The spacing between them is what keeps that from
/// being a pile-up, so this turns the real thing through a whole revolution
/// and looks for any two marks touching.
void main() {
  setUp(() => NestMotion.debugHoldStill = false);
  tearDown(() => NestMotion.debugHoldStill = true);

  for (final width in [340.0, 280.0]) {
    testWidgets('no two marks ever touch while the rings turn, at $width', (
      tester,
    ) async {
      await pumpKit(
        tester,
        SizedBox(width: width, child: const SignInWelcome()),
      );
      final marks = find.descendant(
        of: find.byType(NestOrbit),
        matching: find.byWidgetPredicate(
          (widget) =>
              widget is NestAvatar ||
              widget is NestIconTile ||
              widget is NestDot,
        ),
      );
      expect(marks, findsNWidgets(16));

      // One revolution, in steps much smaller than any mark passes another in.
      const steps = 240;
      final step = const Duration(seconds: 60) ~/ steps;
      await tester.pump(const Duration(seconds: 2));
      for (var i = 0; i < steps; i++) {
        final rects = [
          for (final element in marks.evaluate())
            tester.getRect(find.byWidget(element.widget)),
        ];
        for (var a = 0; a < rects.length; a++) {
          for (var b = a + 1; b < rects.length; b++) {
            final apart =
                (rects[a].center - rects[b].center).distance >=
                (rects[a].shortestSide + rects[b].shortestSide) / 2;
            expect(apart, isTrue, reason: '${rects[a]} touched ${rects[b]}');
          }
        }
        await tester.pump(step);
      }
      await tester.pumpWidget(const SizedBox());
    });
  }

  testWidgets('it rests under reduce-motion', (tester) async {
    await pumpKit(tester, const SignInWelcome(), reduceMotion: true);
    await tester.pumpAndSettle();
    expect(tester.binding.hasScheduledFrame, isFalse);
  });
}
