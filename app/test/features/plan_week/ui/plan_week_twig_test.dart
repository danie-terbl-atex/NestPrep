import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/design/nest_kit.dart';
import 'package:nestprep/features/groceries/model/product_match.dart';
import 'package:nestprep/features/lunch_box/model/lunch_budget.dart';
import 'package:nestprep/features/plan_week/state/plan_week_controller.dart';
import 'package:nestprep/features/plan_week/ui/plan_week_screen.dart';
import 'package:nestprep/shared/copy/app_copy.dart';
import 'package:nestprep/shared/failure/app_failure.dart';
import 'package:provider/provider.dart';

import '../../../support/fake_plan_week.dart';
import '../../../support/plan_week_one_idea.dart';
import '../../../support/plan_week_rig.dart';
import '../../../support/pump_screen.dart';

/// Twig means *AI did this* (design-system ADR-0012): it is on every step the
/// model works or worked — the drafting and building waits, the done step of
/// a week it built — and absent from every
/// wait the phone does itself, every phone-built answer and every failure.
void main() {
  late PlanWeekRig rig;

  setUp(() => rig = PlanWeekRig()..stockOneIdeaWeek());
  tearDown(() => rig.close());

  Finder twig([NestTwigPose? pose]) => find.byWidgetPredicate(
    (widget) => widget is NestTwig && (pose == null || widget.pose == pose),
  );

  Future<void> pump(
    WidgetTester tester, {
    Brightness brightness = Brightness.light,
    double scale = 1,
    Size size = const Size(420, 5000),
  }) async {
    tester.view.physicalSize = size * 3;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await pumpScreen(
      tester,
      const PlanWeekScreen(),
      providers: [
        ...rig.harness.lunch.providers,
        ...rig.harness.providers,
        ChangeNotifierProvider<PlanWeekController>.value(value: rig.controller),
        planWeekCartsProvider(),
      ],
      brightness: brightness,
      textScale: scale,
    );
    rig.harness.lunch.emit();
    rig.harness.emitPlanning(
      budget: const LunchBudget(id: 'weekly', cents: 30000, updatedBy: 'm'),
    );
    await tester.pumpAndSettle();
  }

  Future<void> tapKey(
    WidgetTester tester,
    String key, {
    bool settle = true,
  }) async {
    final target = find.byKey(ValueKey(key));
    await tester.scrollUntilVisible(
      target,
      300,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(target);
    if (settle) {
      await tester.pumpAndSettle();
    } else {
      // The working loop keeps moving while it waits, so nothing settles.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
    }
  }

  Future<void> toIdeas(WidgetTester tester) =>
      tapKey(tester, 'plan-week-ideas');

  testWidgets('reading the lunchbox aisle is the phone\'s work: the mark, '
      'not Twig', (tester) async {
    rig.aisle.gate = Completer<void>();
    await pump(tester);
    await tapKey(tester, 'plan-week-ideas', settle: false);
    expect(find.text(PlanWeekCopy.aisleTitle), findsWidgets);
    expect(find.byType(NestBrandMark), findsOneWidget);
    expect(twig(), findsNothing);
    expect(rig.controller.ideas.isDrafting, isFalse);
    rig.aisle.gate!.complete();
    await tester.pumpAndSettle();
  });

  testWidgets('while the model drafts ideas, Twig thinks', (tester) async {
    rig.drafter.gate = Completer<void>();
    await pump(tester);
    await tapKey(tester, 'plan-week-ideas', settle: false);
    expect(find.text(PlanWeekCopy.draftingTitle), findsWidgets);
    expect(twig(NestTwigPose.thinking), findsOneWidget);
    expect(find.byType(NestBrandMark), findsNothing);
    expect(rig.controller.ideas.isDrafting, isTrue);
    rig.drafter.gate!.complete();
    await tester.pumpAndSettle();
    expect(
      find.text(PlanWeekCopy.ideasHeadline(ProductRetailer.checkers)),
      findsOneWidget,
    );
    expect(twig(), findsNothing);
    expect(rig.controller.ideas.isDrafting, isFalse);
  });

  testWidgets('searching the shop is the phone\'s work: the mark, not Twig', (
    tester,
  ) async {
    await pump(tester);
    await toIdeas(tester);
    rig.shop.gate = Completer<void>();
    await tapKey(tester, 'plan-week-search', settle: false);
    expect(
      find.text(PlanWeekCopy.storeTitle(ProductRetailer.checkers)),
      findsWidgets,
    );
    expect(find.byType(NestBrandMark), findsOneWidget);
    expect(twig(), findsNothing);
    rig.shop.gate!.complete();
    await tester.pumpAndSettle();
  });

  testWidgets('while the model builds the week, Twig plans; a week it built '
      'is celebrated by Twig, labelled for a screen reader', (tester) async {
    await pump(tester);
    await toIdeas(tester);
    rig.builder.gate = Completer<void>();
    await tapKey(tester, 'plan-week-search', settle: false);
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text(PlanWeekCopy.buildingTitle), findsWidgets);
    expect(twig(NestTwigPose.planning), findsOneWidget);
    rig.builder.gate!.complete();
    await tester.pumpAndSettle();
    expect(twig(), findsNothing, reason: 'the week itself is the parent\'s');

    await tapKey(tester, 'plan-week-use');
    expect(find.text(PlanWeekCopy.doneTitle), findsOneWidget);
    expect(twig(NestTwigPose.celebrate), findsOneWidget);
    expect(
      find.bySemanticsLabel('Planned by Twig, NestPrep’s AI'),
      findsOneWidget,
    );
  });

  const fallbacks = <String, AppFailure>{
    'AI is off': AiFailure(AiProblem.aiSwitchedOff),
    'the month is spent': AiFailure(AiProblem.aiLimitReached),
    'AI is not answering': AiFailure(AiProblem.aiUnavailable),
    'the phone is offline': UnavailableFailure(),
  };

  for (final MapEntry(key: why, value: failure) in fallbacks.entries) {
    testWidgets('when $why, ideas from the library carry no Twig', (
      tester,
    ) async {
      rig.drafter.failWith = failure;
      await pump(tester);
      await toIdeas(tester);
      expect(
        find.text(PlanWeekCopy.ideasHeadline(ProductRetailer.checkers)),
        findsOneWidget,
      );
      expect(twig(), findsNothing);
    });

    testWidgets('when $why, a week built on the phone ends without Twig', (
      tester,
    ) async {
      rig.builder.failWith = failure;
      await pump(tester);
      await toIdeas(tester);
      await tapKey(tester, 'plan-week-search');
      expect(twig(), findsNothing);
      await tapKey(tester, 'plan-week-use');
      expect(find.text(PlanWeekCopy.doneTitle), findsOneWidget);
      expect(twig(), findsNothing);
      expect(find.byIcon(LucideIcons.check), findsOneWidget);
    });
  }

  // Twig is named in words when it could not help, and never shown
  // (design-system ADR-0012, ADR-0014).
  const twigCouldNotHelp = <String, AiFailure>{
    'Twig’s planning is paused for now.': AiFailure(AiProblem.aiSwitchedOff),
    'Twig’s plans for this month are used up — they come back on the 1st.':
        AiFailure(AiProblem.aiLimitReached),
    'Twig didn’t answer just now.': AiFailure(AiProblem.aiUnavailable),
  };

  for (final MapEntry(key: words, value: failure) in twigCouldNotHelp.entries) {
    testWidgets('ideas from the library say "$words", with no Twig picture', (
      tester,
    ) async {
      rig.drafter.failWith = failure;
      await pump(tester);
      await toIdeas(tester);
      expect(
        find.text('$words So these ideas come from your own lunch library.'),
        findsOneWidget,
      );
      expect(twig(), findsNothing);
    });

    testWidgets('a week built on the phone says "$words", with no Twig '
        'picture', (tester) async {
      rig.builder.failWith = failure;
      await pump(tester);
      await toIdeas(tester);
      await tapKey(tester, 'plan-week-search');
      expect(find.textContaining('$words So the phone built it'), findsOne);
      expect(twig(), findsNothing);
    });
  }

  testWidgets('a draft that fails outright is an error view, without Twig', (
    tester,
  ) async {
    rig.drafter.failWith = const PlanWeekFailure(
      PlanWeekProblem.weekNotPlannable,
    );
    await pump(tester);
    await toIdeas(tester);
    expect(find.text(AppCopy.retry), findsOneWidget);
    expect(twig(), findsNothing);
  });

  testWidgets('a build that fails outright is an error view, without Twig', (
    tester,
  ) async {
    rig.builder.failWith = const PlanWeekFailure(
      PlanWeekProblem.weekNotPlannable,
    );
    await pump(tester);
    await toIdeas(tester);
    await tapKey(tester, 'plan-week-search');
    expect(find.text(AppCopy.retry), findsOneWidget);
    expect(twig(), findsNothing);
  });

  testWidgets('Twig\'s waits hold dark at 200% text on a small phone', (
    tester,
  ) async {
    await pump(
      tester,
      brightness: Brightness.dark,
      scale: 2,
      size: const Size(360, 800),
    );
    rig.drafter.gate = Completer<void>();
    await tapKey(tester, 'plan-week-ideas', settle: false);
    expect(twig(NestTwigPose.thinking), findsOneWidget);
    expect(tester.takeException(), isNull, reason: 'drafting');
    rig.drafter.gate!.complete();
    await tester.pumpAndSettle();

    rig.builder.gate = Completer<void>();
    await tapKey(tester, 'plan-week-search', settle: false);
    await tester.pump(const Duration(milliseconds: 400));
    expect(twig(NestTwigPose.planning), findsOneWidget);
    expect(tester.takeException(), isNull, reason: 'building');
    rig.builder.gate!.complete();
    await tester.pumpAndSettle();
  });
}
