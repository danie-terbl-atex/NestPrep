import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/plan_week/ui/plan_week_screen.dart';
import 'package:nestprep/shared/failure/app_failure.dart';
import 'package:timezone/data/latest.dart' as tz_data;

import 'plan_week_press.dart';
import 'review_press.dart';

/// Twig in *Plan my week* (design-system ADR-0012), in the design-review
/// press: the model drafting and building (held still, as reduce-motion shows
/// them), both themes — and done after a week built on the phone, which has
/// no Twig. Regenerate with
///
///     flutter test tool/plan_week_twig_design_review_test.dart --update-goldens
void main() {
  setUpAll(() async {
    tz_data.initializeTimeZones();
    await loadEveryFont();
  });

  for (final (brightness, suffix) in [
    (Brightness.light, 'light'),
    (Brightness.dark, 'dark'),
  ]) {
    testWidgets(
      'the model drafting ideas, $suffix',
      (tester) => capturePlanWeek(
        tester,
        'plan-week-drafting-$suffix',
        heldStill(const PlanWeekScreen()),
        brightness: brightness,
        isDraftHeld: true,
        act: (controller) async => unawaited(controller.draftIdeas()),
      ),
    );

    testWidgets(
      'the model building the week, $suffix',
      (tester) => capturePlanWeek(
        tester,
        'plan-week-building-$suffix',
        heldStill(const PlanWeekScreen()),
        brightness: brightness,
        isBuildHeld: true,
        act: (controller) async {
          await controller.draftIdeas();
          unawaited(controller.searchStore());
        },
      ),
    );
  }

  testWidgets(
    'done, after a week built on the phone',
    (tester) => capturePlanWeek(
      tester,
      'plan-week-done-without-ai-light',
      const PlanWeekScreen(),
      act: (controller) async {
        await controller.draftIdeas();
        await controller.searchStore();
        await controller.use();
      },
      buildRefusal: const AiFailure(AiProblem.aiLimitReached),
    ),
  );
}
