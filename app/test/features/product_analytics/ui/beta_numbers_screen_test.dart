import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/product_analytics/state/beta_numbers_controller.dart';
import 'package:nestprep/features/product_analytics/ui/beta_numbers_screen.dart';
import 'package:nestprep/shared/copy/app_copy.dart';
import 'package:nestprep/shared/failure/app_failure.dart';
import 'package:nestprep/shared/time/calendar_date.dart';
import 'package:provider/provider.dart';

import '../../../support/fake_product_analytics.dart';
import '../../../support/pump_screen.dart';

/// The Beta numbers screen (product-analytics ADR-0001): the three numbers,
/// week by week, and all four states (`FE-08`).
void main() {
  const copy = AppCopy.productAnalytics;
  // Thursday 1 October 2026, in week 40 (Monday 28 September).
  final today = DateTime(2026, 10, 1, 9);
  final thisMonday = CalendarDate(2026, 9, 28);
  final lastMonday = CalendarDate(2026, 9, 21);

  late FakeBetaNumbersRepository repository;
  late BetaNumbersController controller;

  setUp(() {
    repository = FakeBetaNumbersRepository(isReader: true);
    controller = BetaNumbersController(
      betaNumbersRepository: repository,
      now: () => today,
    );
  });

  tearDown(() async {
    controller.dispose();
    await repository.close();
  });

  Future<void> pump(
    WidgetTester tester, {
    Brightness brightness = Brightness.light,
    double scale = 1,
  }) => pumpScreen(
    tester,
    const BetaNumbersScreen(),
    providers: [
      ChangeNotifierProvider<BetaNumbersController>.value(value: controller),
    ],
    brightness: brightness,
    textScale: scale,
  );

  final twoWeeks = [
    weekOf(
      '2026-W40',
      thisMonday,
      activeFamilies: 12,
      familiesSeen: 20,
      lunchPlansCreated: 31,
      familiesPlanningLunches: 9,
      newFamilies: 4,
      newFamiliesInvitingAnAdult: 3,
      computedAt: DateTime(2026, 10, 1, 3),
    ),
    weekOf(
      '2026-W39',
      lastMonday,
      activeFamilies: 7,
      familiesSeen: 11,
      lunchPlansCreated: 1,
      familiesPlanningLunches: 1,
      isInviteCohortComplete: true,
    ),
  ];

  group('the four states', () {
    testWidgets('holds the layout while it loads', (tester) async {
      await pump(tester);
      await tester.pump();

      expect(find.byKey(const ValueKey('loading')), findsOneWidget);
      expect(find.text(copy.title), findsOneWidget);
    });

    testWidgets('says when the first numbers will appear, before any exist', (
      tester,
    ) async {
      await pump(tester);
      repository.emitWeeks(const []);
      await tester.pumpAndSettle();

      expect(find.text(copy.emptyTitle), findsOneWidget);
      expect(find.text(copy.emptyBody), findsOneWidget);
    });

    testWidgets('shows a refusal as copy, never the raw error', (tester) async {
      await pump(tester);
      repository.failWeeksWith(const PermissionDeniedFailure());
      await tester.pumpAndSettle();

      expect(
        find.text(AppCopy.failure(const PermissionDeniedFailure())),
        findsOneWidget,
      );
      expect(find.text(AppCopy.retry), findsOneWidget);
    });

    testWidgets('shows the weeks once they arrive', (tester) async {
      await pump(tester);
      repository.emitWeeks(twoWeeks);
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('data')), findsOneWidget);
    });
  });

  group('this week', () {
    testWidgets('leads, with each number and what it is out of', (
      tester,
    ) async {
      await pump(tester);
      repository.emitWeeks(twoWeeks);
      await tester.pumpAndSettle();

      expect(find.text(copy.thisWeek), findsOneWidget);
      expect(find.text('12'), findsOneWidget);
      expect(find.text(copy.activeFamiliesDetail(20)), findsOneWidget);
      expect(find.text('31'), findsOneWidget);
      expect(find.text(copy.lunchPlansDetail(9)), findsOneWidget);
      expect(find.text(copy.percent(75)), findsOneWidget);
      expect(
        find.text(
          copy.inviteRateDetail(
            inviting: 3,
            newFamilies: 4,
            isStillCounting: true,
          ),
        ),
        findsOneWidget,
      );
      expect(find.text(copy.counted(AppCopy.dateToday)), findsOneWidget);
    });

    testWidgets('marks an invite rate that is still counting', (tester) async {
      await pump(tester);
      repository.emitWeeks(twoWeeks);
      await tester.pumpAndSettle();

      // This week's cohort is still inside its first week; last week had
      // nobody new, so it has no rate to qualify.
      expect(find.textContaining(copy.stillCounting), findsOneWidget);
    });

    testWidgets('says "no new families" rather than a 0% that never happened', (
      tester,
    ) async {
      await pump(tester);
      repository.emitWeeks(twoWeeks);
      await tester.pumpAndSettle();

      expect(find.text(copy.noNewFamilies), findsOneWidget);
      expect(find.text(copy.percent(0)), findsNothing);
    });
  });

  testWidgets('files the earlier weeks under their own heading', (
    tester,
  ) async {
    await pump(tester);
    repository.emitWeeks(twoWeeks);
    await tester.pumpAndSettle();

    expect(find.text(copy.earlierWeeks), findsOneWidget);
    expect(find.text('21 – 27 Sep'), findsOneWidget);
    await tester.scrollUntilVisible(find.text(copy.howCountedTitle), 200);
    expect(find.text(copy.howCountedTitle), findsOneWidget);
  });

  testWidgets(
    'does not call a stale week "this week" when the rollup has not run',
    (tester) async {
      await pump(tester);
      repository.emitWeeks([twoWeeks.last]);
      await tester.pumpAndSettle();

      expect(find.text(copy.thisWeek), findsNothing);
      expect(find.text(copy.earlierWeeks), findsOneWidget);
    },
  );

  testWidgets('survives dark at 200% text on a 360-wide phone', (tester) async {
    tester.view.physicalSize = const Size(360 * 3, 800 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await pump(tester, brightness: Brightness.dark, scale: 2);
    repository.emitWeeks(twoWeeks);
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });
}
