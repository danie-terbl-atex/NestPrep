import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:nestprep/app/household_shell.dart';
import 'package:nestprep/features/household/model/access_grant.dart';
import 'package:nestprep/features/household/model/access_level.dart';
import 'package:nestprep/features/household/model/household.dart';
import 'package:nestprep/features/household/model/household_area.dart';
import 'package:nestprep/features/household/state/household_controller.dart';
import 'package:provider/provider.dart';

import '../support/fake_household.dart';
import '../support/household_fixtures.dart';
import '../support/pump_screen.dart';

/// The shell acting on `householdPlaceRedirect` once the household is in hand
/// (household ADR-0003): the redirect itself is tested on its own; this is
/// the wiring, where a helper who may only clean opens the app on the week
/// and has to end up somewhere they may be.
void main() {
  late FakeHouseholdRepository repository;
  late HouseholdController controller;

  tearDown(() async {
    controller.dispose();
    await repository.close();
  });

  Future<void> openOnTheWeek(WidgetTester tester, {required String viewer}) {
    repository = FakeHouseholdRepository();
    controller = HouseholdController(
      householdRepository: repository,
      householdDirectory: FakeHouseholdDirectory(),
      householdId: Fixtures.householdId,
      viewerUid: viewer,
    );
    return pumpRouter(
      tester,
      router: GoRouter(
        initialLocation: '/households/${Fixtures.householdId}/week',
        routes: [
          ShellRoute(
            builder: (context, state, child) =>
                ChangeNotifierProvider<HouseholdController>.value(
                  value: controller,
                  child: HouseholdShell(location: state.uri.path, child: child),
                ),
            routes: [
              GoRoute(
                path: '/households/:householdId/:place',
                builder: (context, state) =>
                    Text('on ${state.pathParameters['place']}'),
              ),
            ],
          ),
        ],
      ),
      providers: const [],
    );
  }

  testWidgets('a new household’s admin is taken to the invite step', (
    tester,
  ) async {
    await openOnTheWeek(tester, viewer: Fixtures.samUid);
    repository.emitHousehold(
      Fixtures.household().copyWith(
        pendingSetupStep: Household.invitePeopleStep,
      ),
    );
    repository.emitMembers([Fixtures.sam]);
    await tester.pumpAndSettle();

    expect(find.text('on setup'), findsOneWidget);
  });

  testWidgets('a helper who may only clean lands on the household screen', (
    tester,
  ) async {
    await openOnTheWeek(tester, viewer: Fixtures.thandiUid);
    repository.emitHousehold(
      Fixtures.household().copyWith(
        access: {
          Fixtures.thandiUid: AccessGrant({
            HouseholdArea.homeCare: AccessLevel.own,
          }),
        },
      ),
    );
    repository.emitMembers([Fixtures.sam, Fixtures.thandi]);
    await tester.pumpAndSettle();

    expect(find.text('on household'), findsOneWidget);
  });

  testWidgets('family stays on the week', (tester) async {
    await openOnTheWeek(tester, viewer: Fixtures.samUid);
    repository.emitHousehold(Fixtures.household());
    repository.emitMembers([Fixtures.sam]);
    await tester.pumpAndSettle();

    expect(find.text('on week'), findsOneWidget);
  });
}
