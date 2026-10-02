import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:nestprep/app/home_care_route.dart';
import 'package:nestprep/app/household_place_redirect.dart';
import 'package:nestprep/app/household_route.dart';
import 'package:nestprep/features/household/model/household_view.dart';
import 'package:nestprep/features/household/ui/household_places.dart';
import 'package:nestprep/shared/copy/app_copy.dart';

import '../../../support/home_care_fixtures.dart';
import '../../../support/household_fixtures.dart';
import '../../../support/pump_screen.dart';

/// Home care is reached from the household screen, for whoever the
/// `homeCare` grant lets see it — a capability with no way in is not done
/// (the vault lesson), and a way in for somebody the rules refuse is a door
/// that opens onto an error.
void main() {
  const id = Fixtures.householdId;

  Future<void> pumpPlaces(WidgetTester tester, HouseholdView view) async {
    tester.view.physicalSize = const Size(420, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await pumpRouter(
      tester,
      view: view,
      providers: const [],
      router: GoRouter(
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => Scaffold(
              body: SingleChildScrollView(child: HouseholdPlaces(view: view)),
            ),
          ),
          GoRoute(
            path: HomeCareRoute.path,
            builder: (context, state) => const Text('home care'),
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('a parent finds home care on the household screen', (
    tester,
  ) async {
    await pumpPlaces(tester, Fixtures.view());
    expect(find.text(HomeCareCopy.openFromHouseholdBody), findsOneWidget);
    await tester.tap(find.text(HomeCareCopy.openFromHousehold));
    await tester.pumpAndSettle();
    expect(find.text('home care'), findsOneWidget);
  });

  testWidgets('a helper finds her own jobs there', (tester) async {
    await pumpPlaces(tester, HomeCareFixtures.helperView());
    expect(find.text(HomeCareCopy.openFromHouseholdHelperBody), findsOneWidget);
  });

  testWidgets('somebody with no home care is not shown the way in', (
    tester,
  ) async {
    await pumpPlaces(tester, HomeCareFixtures.noCleaningView());
    expect(find.text(HomeCareCopy.openFromHousehold), findsNothing);
  });

  group('a deep link', () {
    test('is no way round a grant of none', () {
      expect(
        householdPlaceRedirect(
          location: HomeCareRoute.jobPathFor(id, 'oven'),
          view: HomeCareFixtures.noCleaningView(),
        ),
        isNotNull,
      );
    });

    test('lets a helper holding `own` in', () {
      expect(
        householdPlaceRedirect(
          location: HomeCareRoute.stepsPathFor(id, 'oven'),
          view: HomeCareFixtures.helperView(),
        ),
        isNull,
      );
    });

    test('and never touches the household screen itself', () {
      expect(
        householdPlaceRedirect(
          location: HouseholdRoute.householdPathFor(id),
          view: HomeCareFixtures.noCleaningView(),
        ),
        isNull,
      );
    });
  });
}
