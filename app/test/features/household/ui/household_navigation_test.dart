import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:nestprep/app/household_route.dart';
import 'package:nestprep/app/household_shell.dart';
import 'package:nestprep/design/nest_kit.dart';
import 'package:nestprep/features/household/model/household_view.dart';
import 'package:nestprep/features/household/ui/household_people_card.dart';
import 'package:nestprep/shared/copy/app_copy.dart';
import 'package:provider/provider.dart';

import '../../../support/household_fixtures.dart';

/// Leaving More for the people screen and coming back.
///
/// This was broken: the link *replaced* the location instead of pushing, so
/// there was nothing to pop and the system back button closed the app
/// (`FE-17`). Asserting on the router's reported location would not have caught
/// it — go_router reports the base location either way — so these tests assert
/// what a person actually sees and whether there is anywhere to go back to.
void main() {
  const moreTitle = 'More';

  /// The household screen as the route builds it: a back button only when
  /// something pushed it.
  Widget householdScreen(BuildContext context) => NestScaffold(
    title: AppCopy.householdTitle,
    leading: context.canPop()
        ? NestIconButton(
            icon: LucideIcons.arrowLeft,
            label: AppCopy.back,
            onPressed: context.pop,
          )
        : null,
    body: const SizedBox.shrink(),
  );

  GoRouter routerFrom(String initialLocation) => GoRouter(
    initialLocation: initialLocation,
    routes: [
      GoRoute(
        path: '${HouseholdRoute.path}/${HouseholdTab.more.segment}',
        builder: (context, state) => NestScaffold(
          title: moreTitle,
          body: HouseholdPeopleCard(view: Fixtures.view()),
        ),
      ),
      GoRoute(
        path: '${HouseholdRoute.path}/${HouseholdRoute.householdSegment}',
        builder: (context, state) => householdScreen(context),
      ),
    ],
  );

  Future<void> pump(WidgetTester tester, GoRouter router) async {
    await tester.pumpWidget(
      Provider<HouseholdView>.value(
        value: Fixtures.view(),
        child: MaterialApp.router(
          theme: nestThemeData(NestTheme.light()),
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('the people screen opens over More, not instead of it', (
    tester,
  ) async {
    await pump(
      tester,
      routerFrom(
        HouseholdRoute.pathFor(Fixtures.householdId, HouseholdTab.more),
      ),
    );
    expect(find.text(moreTitle), findsOneWidget);

    await tester.tap(find.text(MoreCopy.peopleTitle));
    await tester.pumpAndSettle();

    expect(find.text(AppCopy.householdTitle), findsOneWidget);
    // The whole point: there is somewhere to go back to. Without this, the
    // system back button closes the app.
    expect(find.byIcon(LucideIcons.arrowLeft), findsOneWidget);
  });

  testWidgets('going back lands on More', (tester) async {
    await pump(
      tester,
      routerFrom(
        HouseholdRoute.pathFor(Fixtures.householdId, HouseholdTab.more),
      ),
    );
    await tester.tap(find.text(MoreCopy.peopleTitle));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(LucideIcons.arrowLeft));
    await tester.pumpAndSettle();

    expect(find.text(moreTitle), findsOneWidget);
    expect(find.text(AppCopy.householdTitle), findsNothing);
  });

  testWidgets('a deep link straight to the household offers no way back', (
    tester,
  ) async {
    await pump(
      tester,
      routerFrom(HouseholdRoute.householdPathFor(Fixtures.householdId)),
    );

    expect(find.text(AppCopy.householdTitle), findsOneWidget);
    // Nothing pushed it, so a back button would lead nowhere.
    expect(find.byIcon(LucideIcons.arrowLeft), findsNothing);
  });
}
