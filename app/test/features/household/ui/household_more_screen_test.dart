import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/household/model/access_grant.dart';
import 'package:nestprep/features/household/model/access_level.dart';
import 'package:nestprep/features/household/model/household_area.dart';
import 'package:nestprep/features/household/model/household_view.dart';
import 'package:nestprep/features/household/ui/household_more_screen.dart';
import 'package:nestprep/shared/copy/app_copy.dart';
import 'package:nestprep/shared/copy/points_copy.dart';
import 'package:nestprep/shared/copy/subscription_copy.dart';

import '../../../support/household_fixtures.dart';
import '../../../support/pump_screen.dart';

/// More: the household's people and every place beyond the bar, one tap from
/// any tab (design-system ADR-0005). The places used to sit at the foot of
/// the people screen, where nobody found them; each is shown only to
/// somebody the household's grant lets use it (household ADR-0003).
void main() {
  final cleaningOnly = Fixtures.helperView(
    AccessGrant({HouseholdArea.homeCare: AccessLevel.own}),
  );

  Future<void> pump(
    WidgetTester tester, {
    HouseholdView? view,
    Brightness brightness = Brightness.light,
    double scale = 1,
  }) async {
    await pumpScreen(
      tester,
      HouseholdMoreScreen(onSelectTab: (_) {}),
      providers: const [],
      view: view,
      brightness: brightness,
      textScale: scale,
    );
    await tester.pumpAndSettle();
  }

  /// A tall phone, for a test about where a tap goes rather than where the
  /// control sits.
  void tallPhone(WidgetTester tester) {
    tester.view.physicalSize = const Size(420 * 3, 1600 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
  }

  /// Scrolled to before it is asserted on, so "not found" means not there
  /// rather than not built yet.
  Future<void> scrollTo(WidgetTester tester, String text) =>
      tester.scrollUntilVisible(find.text(text), 200);

  testWidgets('family sees the people, then each section and its places', (
    tester,
  ) async {
    await pump(tester);

    expect(find.text(MoreCopy.peopleTitle), findsOneWidget);
    expect(find.text(MoreCopy.peopleCount(3)), findsOneWidget);
    for (final text in [
      MoreCopy.sectionWeek,
      AppCopy.tabMeals,
      PointsCopy.screenTitle,
      MoreCopy.sectionFamily,
      FamilyCopy.openFromHousehold,
      AppCopy.locationTitle,
      MoreCopy.sectionHome,
      HomeCareCopy.openFromHousehold,
      AppCopy.documentsOpenLibrary,
      MoreCopy.sectionPlan,
      SubscriptionCopy.openFromHousehold,
    ]) {
      await scrollTo(tester, text);
      expect(find.text(text), findsOneWidget, reason: text);
    }
  });

  testWidgets('a helper who may only clean sees their jobs and where '
      'everybody is, and nothing their grant does not open', (tester) async {
    await pump(tester, view: cleaningOnly);

    await scrollTo(tester, HomeCareCopy.openFromHousehold);
    expect(
      find.text(HomeCareCopy.openFromHouseholdHelperBody),
      findsOneWidget,
      reason: 'a helper is told the jobs are the ones assigned to them',
    );
    await scrollTo(tester, AppCopy.locationTitle);

    for (final text in [
      AppCopy.tabMeals,
      PointsCopy.screenTitle,
      FamilyCopy.openFromHousehold,
      AppCopy.documentsOpenLibrary,
      MoreCopy.sectionWeek,
      MoreCopy.sectionPlan,
      SubscriptionCopy.openFromHousehold,
    ]) {
      expect(find.text(text), findsNothing, reason: text);
    }
    expect(
      find.text(MoreCopy.peopleManageForMembers),
      findsOneWidget,
      reason: 'only an admin is told they can manage people',
    );
  });

  group('the way to where everybody is', () {
    testWidgets('says what it is before it is tapped', (tester) async {
      await pump(tester);
      await scrollTo(tester, MoreCopy.locationBody);
      expect(find.text(AppCopy.locationTitle), findsOneWidget);
    });

    testWidgets('goes there, and pushes so that back comes back here', (
      tester,
    ) async {
      // Two failures in one test. The first is the one this app has had
      // twice: a capability finished everywhere but the screen, with no
      // control that opened it. The second is `go` where `push` was meant —
      // identical until somebody presses back and the app closes (`FE-17`).
      tallPhone(tester);
      await pump(tester);
      await tester.tap(find.text(AppCopy.locationTitle));
      await tester.pumpAndSettle();
      expect(find.byType(Placeholder), findsOneWidget);

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.text(MoreCopy.subtitle), findsOneWidget);
    });

    testWidgets('is offered to a helper exactly as it is to an admin', (
      tester,
    ) async {
      // Nothing here is an admin action: every member controls their own
      // sharing and nobody else's (live-location ADR-0002).
      await pump(tester, view: cleaningOnly);
      await scrollTo(tester, AppCopy.locationTitle);
      expect(find.text(AppCopy.locationTitle), findsOneWidget);
    });
  });

  testWidgets('the people card opens the people screen, over More', (
    tester,
  ) async {
    tallPhone(tester);
    await pump(tester);
    await tester.tap(find.text(MoreCopy.peopleTitle));
    await tester.pumpAndSettle();
    expect(find.byType(Placeholder), findsOneWidget);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text(MoreCopy.peopleTitle), findsOneWidget);
  });

  testWidgets('it holds at phone width in dark at 200% text', (tester) async {
    tester.view.physicalSize = const Size(360 * 3, 800 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await pump(tester, brightness: Brightness.dark, scale: 2);
    expect(tester.takeException(), isNull);
    // Scrolled through to the last section, so every tile has been laid out
    // at this size, not only the ones that fit on the first screen.
    await scrollTo(tester, SubscriptionCopy.openFromHousehold);
    expect(tester.takeException(), isNull);
    expect(find.text(SubscriptionCopy.openFromHousehold), findsOneWidget);
  });
}
