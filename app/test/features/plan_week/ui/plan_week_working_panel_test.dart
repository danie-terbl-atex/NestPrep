import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/design/nest_kit.dart';
import 'package:nestprep/features/lunch_box/model/lunch_slot.dart';
import 'package:nestprep/features/lunch_box/ui/art/lunch_glyph.dart';
import 'package:nestprep/features/plan_week/ui/plan_week_working_panel.dart';

import '../../../support/pump_kit.dart';

void main() {
  const panel = PlanWeekWorkingPanel(title: 'Working', line: 'On it');

  Finder tile(LunchSlot slot) =>
      find.byWidgetPredicate((w) => w is LunchSlotTile && w.slot == slot);

  Rect markRect(WidgetTester tester) =>
      tester.getRect(find.byType(NestBrandMark));

  testWidgets('keeps moving: the mark breathes and neighbours trade places', (
    tester,
  ) async {
    await pumpKit(tester, panel);
    await tester.pump(const Duration(milliseconds: 600));
    expect(tester.hasRunningAnimations, isTrue);
    expect(
      tester.getTopLeft(tile(LunchSlot.main)).dx,
      lessThan(tester.getTopLeft(tile(LunchSlot.fruit)).dx),
    );
    final restingMark = markRect(tester);

    await tester.pump(const Duration(milliseconds: 300));
    expect(markRect(tester), isNot(restingMark));

    await tester.pump(const Duration(milliseconds: 1000));
    await tester.pump(const Duration(milliseconds: 500));
    expect(
      tester.getTopLeft(tile(LunchSlot.main)).dx,
      greaterThan(tester.getTopLeft(tile(LunchSlot.fruit)).dx),
    );
    expect(tester.hasRunningAnimations, isTrue);
  });

  testWidgets('is still under reduce-motion', (tester) async {
    await pumpKit(tester, panel, reduceMotion: true);
    await tester.pumpAndSettle();
    expect(tester.hasRunningAnimations, isFalse);
    final mark = markRect(tester);
    final main = tester.getTopLeft(tile(LunchSlot.main));

    await tester.pump(const Duration(seconds: 5));
    expect(markRect(tester), mark);
    expect(tester.getTopLeft(tile(LunchSlot.main)), main);
  });

  testWidgets('leaves nothing ticking once it is gone', (tester) async {
    await pumpKit(tester, panel);
    await tester.pump(const Duration(seconds: 2));
    expect(tester.hasRunningAnimations, isTrue);

    await tester.pumpWidget(const SizedBox());
    expect(tester.hasRunningAnimations, isFalse);
  });
}
