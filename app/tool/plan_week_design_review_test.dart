import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/lunch_box/ui/lunch_screen.dart';
import 'package:nestprep/features/plan_week/ui/plan_week_screen.dart';
import 'package:nestprep/shared/failure/app_failure.dart';
import 'package:timezone/data/latest.dart' as tz_data;

import 'plan_week_press.dart';
import 'review_press.dart';

/// *Plan my week from Checkers* in the design-review press (lunch-box
/// ADR-0012): the way in on the board, and its row up close led by the
/// Checkers logo (ADR-0024) light and dark, then the steps that rest — the
/// brief, the ideas (with AI and without), the week and done —
/// light and dark, and the week dark at 200% text. Regenerate with
///
///     flutter test tool/plan_week_design_review_test.dart --update-goldens
void main() {
  setUpAll(() async {
    tz_data.initializeTimeZones();
    await loadEveryFont();
  });

  testWidgets(
    'the way in, on the board',
    (tester) => capturePlanWeek(
      tester,
      'plan-week-board-light',
      LunchScreen(onSelectTab: (_) {}),
    ),
  );

  for (final (brightness, suffix) in [
    (Brightness.light, 'light'),
    (Brightness.dark, 'dark'),
  ]) {
    testWidgets(
      'the way in, scrolled to the card, $suffix',
      (tester) => capturePlanWeek(
        tester,
        'plan-week-entry-$suffix',
        LunchScreen(onSelectTab: (_) {}),
        brightness: brightness,
        act: (_) async {
          final card = find.byKey(const ValueKey('plan-week-open'));
          await tester.scrollUntilVisible(card, 300, scrollable: screenList());
          await tester.pumpAndSettle();
          // The card's top, with the whole card on the screen above the bar.
          await Scrollable.ensureVisible(tester.element(card), alignment: 0.8);
        },
      ),
    );

    for (final (step, act) in [
      ('brief', null),
      ('ideas', toIdeas),
      ('week', toWeek),
      ('done', toDone),
    ]) {
      testWidgets(
        'step $step, $suffix',
        (tester) => capturePlanWeek(
          tester,
          'plan-week-$step-$suffix',
          const PlanWeekScreen(),
          brightness: brightness,
          act: act,
        ),
      );
    }
  }

  testWidgets(
    'the ideas without AI',
    (tester) => capturePlanWeek(
      tester,
      'plan-week-ideas-without-ai-light',
      const PlanWeekScreen(),
      refusal: const AiFailure(AiProblem.aiLimitReached),
      act: toIdeas,
    ),
  );

  testWidgets(
    'the week, dark at 200% text',
    (tester) => capturePlanWeek(
      tester,
      'plan-week-week-dark-200-percent-text',
      const PlanWeekScreen(),
      brightness: Brightness.dark,
      textScale: 2,
      act: toWeek,
    ),
  );

  testWidgets(
    'the basket, further down the week',
    (tester) => capturePlanWeek(
      tester,
      'plan-week-basket-light',
      const PlanWeekScreen(),
      act: (controller) async {
        await toWeek(controller);
        await tester.pumpAndSettle();
        await tester.drag(screenList(), const Offset(0, -2600));
      },
    ),
  );
}
