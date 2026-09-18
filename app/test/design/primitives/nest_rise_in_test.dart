import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/design/nest_kit.dart';
import 'package:nestprep/shared/copy/app_copy.dart';

import '../../support/pump_kit.dart';

/// The entrance every onboarding surface is built out of. Three things matter
/// and none of them is how it looks: it **ends**, it does not **block input**
/// while it runs, and it is **already over** when the platform asks for
/// reduced motion (`FE-15`).
void main() {
  Widget chip(void Function() onTap) =>
      NestChip(label: AppCopy.householdJoin, onTap: onTap);

  for (final brightness in bothThemes) {
    testWidgets('it settles, in ${brightness.name}', (tester) async {
      await pumpKit(
        tester,
        NestRiseIn(child: chip(() {})),
        brightness: brightness,
      );

      // Never returns if anything here repeats, which is the point.
      await tester.pumpAndSettle();

      final opacity = tester.widget<Opacity>(find.byType(Opacity).first);
      expect(opacity.opacity, 1, reason: 'an arrival is over');
    });
  }

  testWidgets('a control can be tapped while it is still arriving', (
    tester,
  ) async {
    var taps = 0;
    await pumpKit(tester, NestRiseIn(child: chip(() => taps++)));

    // The first frame: fully faded out and shifted furthest from home. This
    // is the frame that used to swallow the tap, because the fade sat outside
    // the shift and the hit test stopped at it.
    await tester.tap(find.text(AppCopy.householdJoin));
    await tester.pump(const Duration(milliseconds: 80));
    await tester.tap(find.text(AppCopy.householdJoin));
    await tester.pumpAndSettle();

    expect(taps, 2, reason: 'motion never blocks input (`FE-15`)');
  });

  testWidgets('it starts away from home and arrives at it', (tester) async {
    await pumpKit(tester, const NestRiseIn(child: Text(AppCopy.appName)));

    final start = tester.getTopLeft(find.text(AppCopy.appName));
    await tester.pumpAndSettle();
    final end = tester.getTopLeft(find.text(AppCopy.appName));

    expect(start.dy, greaterThan(end.dy), reason: 'it rises');
  });

  testWidgets('with reduce-motion it is in place on the first frame', (
    tester,
  ) async {
    await pumpKit(
      tester,
      const NestRiseIn(index: 4, child: Text(AppCopy.appName)),
      reduceMotion: true,
    );

    final atOnce = tester.getTopLeft(find.text(AppCopy.appName));
    expect(
      tester.widget<Opacity>(find.byType(Opacity).first).opacity,
      1,
      reason: 'no fade to sit through, however late the step',
    );
    await tester.pumpAndSettle();
    expect(tester.getTopLeft(find.text(AppCopy.appName)), atOnce);
  });

  testWidgets('a later step arrives after an earlier one', (tester) async {
    await pumpKit(
      tester,
      const Column(
        children: [
          NestRiseIn(child: Text(AppCopy.tabWeek)),
          NestRiseIn(index: 3, child: Text(AppCopy.tabMeals)),
        ],
      ),
    );
    await tester.pump(const Duration(milliseconds: 150));

    final first = tester.widget<Opacity>(
      find
          .ancestor(
            of: find.text(AppCopy.tabWeek),
            matching: find.byType(Opacity),
          )
          .first,
    );
    final later = tester.widget<Opacity>(
      find
          .ancestor(
            of: find.text(AppCopy.tabMeals),
            matching: find.byType(Opacity),
          )
          .first,
    );

    expect(first.opacity, greaterThan(later.opacity));
  });
}
