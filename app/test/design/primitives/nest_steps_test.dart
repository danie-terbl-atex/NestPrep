import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/design/nest_kit.dart';

import '../../support/pump_kit.dart';

/// The two step primitives a guided flow is built from: where the parent
/// is, said in words a screen reader hears, and the step's ways on and back.
void main() {
  for (final brightness in bothThemes) {
    group(brightness.name, () {
      testWidgets('the steps bar reads its label alone, never the segments', (
        tester,
      ) async {
        final semantics = tester.ensureSemantics();
        await pumpKit(
          tester,
          const SizedBox(
            width: 320,
            child: NestStepsBar(
              count: 3,
              index: 1,
              label: 'Step 2 of 3: Review',
            ),
          ),
          brightness: brightness,
        );
        expect(find.text('Step 2 of 3: Review'), findsOneWidget);
        expect(find.bySemanticsLabel('Step 2 of 3: Review'), findsOneWidget);
        semantics.dispose();
      });

      testWidgets('each way on and back reports its own tap', (tester) async {
        final taps = <String>[];
        await pumpKit(
          tester,
          SizedBox(
            width: 320,
            child: NestStepActions(
              nextLabel: 'Fill the week',
              nextIcon: LucideIcons.check,
              onNext: () => taps.add('next'),
              secondaryLabel: 'Skip',
              onSecondary: () => taps.add('skip'),
              backLabel: 'Back',
              onBack: () => taps.add('back'),
            ),
          ),
          brightness: brightness,
        );
        await tester.tap(find.text('Fill the week'));
        await tester.tap(find.text('Skip'));
        await tester.tap(find.text('Back'));
        expect(taps, ['next', 'skip', 'back']);
      });

      testWidgets('without a callback the second way and the way back are '
          'not offered, and a busy way on cannot be pressed twice', (
        tester,
      ) async {
        var taps = 0;
        await pumpKit(
          tester,
          SizedBox(
            width: 320,
            child: NestStepActions(
              nextLabel: 'Fill the week',
              nextIcon: LucideIcons.check,
              onNext: () => taps++,
              isBusy: true,
              secondaryLabel: 'Skip',
              backLabel: 'Back',
            ),
          ),
          brightness: brightness,
        );
        expect(find.text('Skip'), findsNothing);
        expect(find.text('Back'), findsNothing);
        await tester.tap(find.byType(NestButton), warnIfMissed: false);
        expect(taps, 0);
      });
    });
  }
}
