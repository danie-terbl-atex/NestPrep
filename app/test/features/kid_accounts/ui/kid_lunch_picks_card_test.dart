import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:nestprep/app/kid_routes.dart';
import 'package:nestprep/app/lunch_planning_route.dart';
import 'package:nestprep/features/kid_accounts/ui/kid_home_screen.dart';
import 'package:nestprep/features/kid_accounts/ui/kid_lunch_picks_card.dart';
import 'package:nestprep/features/lunch_box/model/lunch_choices.dart';
import 'package:nestprep/features/lunch_box/model/lunch_pick.dart';
import 'package:nestprep/features/lunch_box/model/lunch_slot.dart';
import 'package:nestprep/features/lunch_box/state/lunch_choose_controller.dart';
import 'package:nestprep/shared/copy/app_copy.dart';
import 'package:provider/provider.dart';

import '../../../support/fake_lunch_planning.dart';
import '../../../support/fake_lunch_repository.dart';
import '../../../support/household_fixtures.dart';
import '../../../support/lunch_fixtures.dart';
import '../../../support/pump_screen.dart';

/// Lunch to choose, on a kid's home (lunch-box ADR-0008): an invitation that
/// is there only when a grown-up offered something, and the way into the
/// chooser — the one other place a kid device may go.
void main() {
  late FakeLunchRepository plans;
  late FakeLunchChoicesRepository choices;
  late LunchChooseController controller;

  String key(int day, LunchSlot slot) => LunchFixtures.key(day, slot);

  setUp(() {
    plans = FakeLunchRepository();
    choices = FakeLunchChoicesRepository();
    controller = LunchChooseController(
      lunchRepository: plans,
      choicesRepository: choices,
      householdId: Fixtures.householdId,
      childId: LunchFixtures.lwaziId,
    );
  });

  tearDown(() async {
    controller.dispose();
    await plans.close();
    await choices.close();
  });

  Future<void> pump(WidgetTester tester) async {
    await pumpRouter(
      tester,
      router: GoRouter(
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) =>
                const Scaffold(body: Center(child: KidLunchPicksCard())),
          ),
          GoRoute(
            path: LunchPlanningRoute.kidChoosePath,
            builder: (context, state) => const Text('the chooser'),
          ),
        ],
      ),
      providers: [
        ChangeNotifierProvider<LunchChooseController>.value(value: controller),
      ],
    );
    controller.follow(today: LunchFixtures.today);
    await tester.pump();
  }

  Future<void> offer(
    WidgetTester tester,
    Map<String, List<LunchPick>> options,
  ) async {
    plans.emitPlan(LunchFixtures.plan(LunchFixtures.lwaziId));
    choices.emitChoices(
      LunchChoices.none(
        childId: LunchFixtures.lwaziId,
        week: LunchFixtures.week,
      ).copyWith(options: options),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('says nothing while nothing is offered', (tester) async {
    await pump(tester);
    expect(find.text(LunchKidPicksCopy.kidCardTitle), findsNothing);
    await offer(tester, const {});
    expect(find.text(LunchKidPicksCopy.kidCardTitle), findsNothing);
  });

  testWidgets('invites the kid in when a grown-up offered lunch', (
    tester,
  ) async {
    await pump(tester);
    await offer(tester, {
      key(2, LunchSlot.fruit): [
        LunchPick.of(LunchFixtures.apple),
        LunchPick.of(LunchFixtures.grapes),
      ],
      key(3, LunchSlot.fruit): [
        LunchPick.of(LunchFixtures.apple),
        LunchPick.of(LunchFixtures.grapes),
      ],
    });
    expect(find.text(LunchKidPicksCopy.kidCardTitle), findsOneWidget);
    expect(find.text(LunchKidPicksCopy.kidCardBody(2)), findsOneWidget);
    await tester.tap(find.text(LunchKidPicksCopy.kidCardOpen));
    await tester.pumpAndSettle();
    expect(find.text('the chooser'), findsOneWidget);
  });

  test('a kid device may go to its chooser, and nowhere else new', () {
    expect(redirectForKid(LunchPlanningRoute.kidChoosePath), isNull);
    expect(redirectForKid(KidHomeScreen.path), isNull);
    expect(redirectForKid('/kid/lunch/other'), KidHomeScreen.path);
    expect(redirectForKid('/households/h1/lunch'), KidHomeScreen.path);
  });
}
