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

import '../../../support/fake_feature_flag_source.dart';
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
    FakeFeatureFlagSource? flags,
  }) async {
    await pumpScreen(
      tester,
      HouseholdMoreScreen(onSelectTab: (_) {}),
      providers: [if (flags != null) featureFlagsProvider(source: flags)],
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
      PointsCopy.screenTitle,
      MoreCopy.sectionFamily,
      FamilyCopy.openFromHousehold,
      LocationCopy.title,
      MoreCopy.sectionHome,
      HomeCareCopy.openFromHousehold,
      AppCopy.documentsOpenLibrary,
      PhotoFrameCopy.title,
      MoreCopy.sectionPlan,
      SubscriptionCopy.openFromHousehold,
    ]) {
      await scrollTo(tester, text);
      expect(find.text(text), findsOneWidget, reason: text);
    }
  });

  group('the way to photo frames', () {
    testWidgets('goes there, and pushes so that back comes back here', (
      tester,
    ) async {
      tallPhone(tester);
      await pump(tester);
      await tester.drag(find.byType(ListView), const Offset(0, -600));
      await tester.pumpAndSettle();
      await tester.tap(find.text(PhotoFrameCopy.title));
      await tester.pumpAndSettle();
      expect(find.byType(Placeholder), findsOneWidget);

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.text(MoreCopy.subtitle), findsOneWidget);
    });

    testWidgets('is not offered while its switch is off', (tester) async {
      final flags = FakeFeatureFlagSource();
      addTearDown(flags.close);
      await pump(tester, flags: flags);
      flags.emit({'photoFrames': false});
      await tester.pumpAndSettle();

      await scrollTo(tester, SubscriptionCopy.openFromHousehold);
      expect(find.text(PhotoFrameCopy.title), findsNothing);
    });
  });

  testWidgets('a helper who may only clean sees their jobs, and nothing '
      'their grant does not open', (tester) async {
    await pump(tester, view: cleaningOnly);

    await scrollTo(tester, HomeCareCopy.openFromHousehold);
    expect(
      find.text(HomeCareCopy.openFromHouseholdHelperBody),
      findsOneWidget,
      reason: 'a helper is told the jobs are the ones assigned to them',
    );

    for (final text in [
      LocationCopy.title,
      PointsCopy.screenTitle,
      FamilyCopy.openFromHousehold,
      AppCopy.documentsOpenLibrary,
      PhotoFrameCopy.title,
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
      expect(find.text(LocationCopy.title), findsOneWidget);
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
      await tester.tap(find.text(LocationCopy.title));
      await tester.pumpAndSettle();
      expect(find.byType(Placeholder), findsOneWidget);

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.text(MoreCopy.subtitle), findsOneWidget);
    });

    testWidgets('is hidden from a helper whose grant does not open it', (
      tester,
    ) async {
      // Who sees the map is the location grant (household ADR-0008).
      await pump(tester, view: cleaningOnly);
      await scrollTo(tester, HomeCareCopy.openFromHousehold);
      expect(find.text(LocationCopy.title), findsNothing);
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
