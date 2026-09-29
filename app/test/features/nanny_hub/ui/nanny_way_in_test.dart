import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:nestprep/app/household_place_redirect.dart';
import 'package:nestprep/app/household_route.dart';
import 'package:nestprep/app/nanny_hub_route.dart';
import 'package:nestprep/features/household/model/access_defaults.dart';
import 'package:nestprep/features/household/model/household_view.dart';
import 'package:nestprep/features/household/ui/household_places.dart';
import 'package:nestprep/shared/copy/app_copy.dart';

import '../../../support/household_fixtures.dart';
import '../../../support/nanny_fixtures.dart';
import '../../../support/pump_screen.dart';

/// The hub is reachable — from the household screen, for whoever the
/// `nannyHub` grant opens it to — and a deep link is no way round a grant of
/// `none` (household ADR-0003, the vault lesson on capabilities finished
/// everywhere but the screen).
void main() {
  const id = Fixtures.householdId;

  Future<void> pumpPlaces(WidgetTester tester, HouseholdView view) =>
      pumpRouter(
        tester,
        router: GoRouter(
          routes: [
            GoRoute(
              path: '/',
              builder: (context, state) => Scaffold(
                body: SingleChildScrollView(child: HouseholdPlaces(view: view)),
              ),
            ),
            GoRoute(
              path: NannyHubRoute.path,
              builder: (context, state) => const Text('the hub'),
            ),
          ],
        ),
        providers: const [],
        view: view,
      );

  testWidgets('a carer finds the hub first on the household screen, and it '
      'opens', (tester) async {
    await pumpPlaces(tester, NannyFixtures.carerView());
    expect(find.text(NannyCopy.openFromHousehold), findsOneWidget);
    expect(
      tester.getTopLeft(find.text(NannyCopy.openFromHousehold)).dy,
      lessThan(tester.getTopLeft(find.text(FamilyCopy.openFromHousehold)).dy),
    );
    await tester.tap(find.text(NannyCopy.openFromHousehold));
    await tester.pumpAndSettle();
    expect(find.text('the hub'), findsOneWidget);
  });

  testWidgets('a parent finds it too', (tester) async {
    await pumpPlaces(tester, NannyFixtures.parentView());
    expect(find.text(NannyCopy.openFromHousehold), findsOneWidget);
  });

  testWidgets('a helper whose grant holds no hub is not shown it', (
    tester,
  ) async {
    await pumpPlaces(tester, Fixtures.helperView(AccessDefaults.helper));
    expect(find.text(NannyCopy.openFromHousehold), findsNothing);
  });

  test('a deep link into the hub moves a helper with no hub elsewhere', () {
    final helper = Fixtures.helperView(AccessDefaults.helper);
    for (final place in [
      NannyHubRoute.pathFor(id),
      NannyHubRoute.shiftPathFor(id, 'shift-1'),
      NannyHubRoute.emergencyPathFor(id),
    ]) {
      expect(
        householdPlaceRedirect(location: place, view: helper),
        isNotNull,
        reason: place,
      );
    }
  });

  test('and leaves a carer, or a carer at view, where they are', () {
    for (final view in [
      NannyFixtures.carerView(),
      NannyFixtures.lookOnlyCarerView(),
    ]) {
      expect(
        householdPlaceRedirect(
          location: NannyHubRoute.childPathFor(id, Fixtures.kidMemberId),
          view: view,
        ),
        isNull,
      );
    }
  });

  test('the routes the hub is reached by agree with the route table', () {
    expect(NannyHubRoute.pathFor(id), '/households/h1/nanny');
    expect(
      NannyHubRoute.summaryPathFor(id, 's1'),
      '/households/h1/nanny/summaries/s1',
    );
    expect(NannyHubRoute.path, startsWith(HouseholdRoute.path));
  });
}
