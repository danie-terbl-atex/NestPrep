import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/app/home_care_route.dart';
import 'package:nestprep/design/nest_kit.dart';
import 'package:nestprep/features/home_care/model/shift/helper_shift.dart';
import 'package:nestprep/features/home_care/ui/home_care_screen.dart';
import 'package:nestprep/features/household/model/access_defaults.dart';
import 'package:nestprep/features/household/model/access_level.dart';
import 'package:nestprep/features/household/model/household_area.dart';
import 'package:nestprep/features/household/model/household_view.dart';
import 'package:nestprep/features/subscriptions/model/premium_feature.dart';
import 'package:nestprep/features/subscriptions/model/subscription_offer.dart';
import 'package:nestprep/features/subscriptions/model/subscription_plan.dart';
import 'package:nestprep/features/subscriptions/state/household_entitlement.dart';
import 'package:nestprep/features/subscriptions/ui/paywall_page.dart';
import 'package:nestprep/features/subscriptions/ui/premium_area.dart';
import 'package:nestprep/shared/copy/app_copy.dart';
import 'package:nestprep/shared/copy/subscription_copy.dart';
import 'package:nestprep/shared/failure/app_failure.dart';
import 'package:provider/provider.dart';

import '../../../support/fake_subscriptions.dart';
import '../../../support/home_care_fixtures.dart';
import '../../../support/household_fixtures.dart';
import '../../../support/nanny_fixtures.dart';
import '../../../support/pump_home_care.dart';
import '../../../support/pump_subscriptions.dart';

/// Home care is Premium in full (subscriptions ADR-0008): a household without
/// it meets every one of its addresses locked, never hidden, with nothing
/// behind it listening — whoever opens it, family or not — but for the shifts
/// still open, which it can always clock out (subscriptions ADR-0009).
void main() {
  late HomeCareHarness home;

  setUp(() => home = HomeCareHarness());
  tearDown(() => home.close());

  const id = Fixtures.householdId;
  final places = {
    'the jobs': HomeCareRoute.pathFor(id),
    'a new job': HomeCareRoute.newJobPathFor(id),
    'the rooms': HomeCareRoute.roomsPathFor(id),
    'the products': HomeCareRoute.productsPathFor(id),
    'a job': HomeCareRoute.jobPathFor(id, 'oven'),
    'a job’s steps': HomeCareRoute.stepsPathFor(id, 'oven'),
    'a job’s review': HomeCareRoute.reviewPathFor(id, 'oven'),
    'the routines': HomeCareRoute.routinesPathFor(id),
    'today’s rooms': HomeCareRoute.todayPathFor(id),
    'the stock': HomeCareRoute.stockPathFor(id),
    'the languages': HomeCareRoute.languagesPathFor(id),
    'the shifts': HomeCareRoute.shiftsPathFor(id),
  };

  Future<SubscriptionHarness> openLocked(
    WidgetTester tester, {
    String? location,
    HouseholdView? view,
    bool canBuy = true,
    Brightness brightness = Brightness.light,
    double textScale = 1,
  }) async {
    final subscriptions = SubscriptionHarness();
    if (!canBuy) {
      subscriptions.server.answer = const SubscriptionOffer(
        isAvailable: true,
        canBuy: false,
        cohort: 'a',
        featuredPlan: SubscriptionPlan.yearly,
        productIds: {SubscriptionPlan.yearly: 'nestprep_premium_yearly'},
      );
    }
    await home.pump(
      tester,
      location: location,
      view: view,
      premium: false,
      also: subscriptions.providers,
      brightness: brightness,
      textScale: textScale,
    );
    await tester.pumpAndSettle();
    return subscriptions;
  }

  Future<void> seePremium(WidgetTester tester) async {
    await tester.ensureVisible(find.text(SubscriptionCopy.seePremium));
    await tester.tap(find.text(SubscriptionCopy.seePremium));
    await tester.pumpAndSettle();
  }

  Future<void> scrollSheetTo(WidgetTester tester, Finder finder) =>
      tester.scrollUntilVisible(
        finder,
        200,
        scrollable: find.byType(Scrollable).last,
      );

  for (final MapEntry(key: place, value: location) in places.entries) {
    testWidgets('$place is locked without Premium, and nothing listens', (
      tester,
    ) async {
      await openLocked(tester, location: location);

      expect(tester.takeException(), isNull);
      expect(find.byType(PremiumLockedView), findsOneWidget);
      expect(
        find.text(SubscriptionCopy.headline(PremiumFeature.homeCare)),
        findsOneWidget,
      );
      expect(home.jobs.jobsAskedFor, isEmpty);
      expect(home.shifts.shiftsAskedFor, isEmpty);
      expect(home.shifts.openShiftsAskedFor, [null]);
      expect(home.translations.asked, isEmpty);
    });
  }

  group('a shift left open', () {
    HelperShift open({
      String id = 'shift-1',
      String helperId = Fixtures.thandiMemberId,
    }) => HelperShift(
      id: id,
      helperId: helperId,
      startedBy: helperId,
      startedAt: DateTime.utc(2026, 11, 12, 5, 30),
    );

    Future<void> emitOpen(WidgetTester tester, List<HelperShift> shifts) async {
      home.shifts.emitOpenShifts(shifts);
      await tester.pumpAndSettle();
    }

    Future<void> scrollToEnd(WidgetTester tester) => tester.scrollUntilVisible(
      find.text(HomeCareShiftCopy.endShift),
      200,
      scrollable: find.byType(Scrollable).first,
    );

    Future<void> endIt(WidgetTester tester) async {
      await scrollToEnd(tester);
      await tester.tap(find.text(HomeCareShiftCopy.endShift));
      await tester.pumpAndSettle();
      await tester.tap(find.text(HomeCareShiftCopy.endShift).last);
      await tester.pumpAndSettle();
    }

    testWidgets('a parent sees the helper still on shift under the lock, and '
        'ends it', (tester) async {
      await openLocked(tester);
      await emitOpen(tester, [open(), open(id: 'shift-0')]);

      expect(find.byType(PremiumLockedView), findsOneWidget);
      expect(find.text(SubscriptionCopy.seePremium), findsOneWidget);
      expect(find.text(HomeCareShiftCopy.lockedOpenBody), findsOneWidget);
      expect(find.text(Fixtures.thandi.displayName), findsOneWidget);
      expect(find.text(HomeCareShiftCopy.since('07:30')), findsOneWidget);
      expect(
        find.widgetWithText(NestButton, HomeCareShiftCopy.endShift),
        findsOneWidget,
      );

      await scrollToEnd(tester);
      await tester.tap(find.text(HomeCareShiftCopy.endShift));
      await tester.pumpAndSettle();
      expect(
        find.text(HomeCareShiftCopy.endForTitle(Fixtures.thandi.displayName)),
        findsOneWidget,
      );
      await tester.tap(find.text(HomeCareShiftCopy.cancel));
      await tester.pumpAndSettle();
      expect(home.shifts.writes, isEmpty);

      await endIt(tester);
      expect(home.shifts.methods, ['endShift', 'endShift']);
      expect(
        [for (final write in home.shifts.writes) write.$2],
        [
          {'shiftId': 'shift-1', 'by': Fixtures.samMemberId},
          {'shiftId': 'shift-0', 'by': Fixtures.samMemberId},
        ],
      );
      expect(home.jobs.jobsAskedFor, isEmpty);
      expect(home.shifts.shiftsAskedFor, isEmpty);

      await emitOpen(tester, const []);
      expect(find.text(HomeCareShiftCopy.endShift), findsNothing);
      expect(find.byType(PremiumLockedView), findsOneWidget);
    });

    testWidgets('a helper is asked only for her own, and ends it herself', (
      tester,
    ) async {
      await openLocked(
        tester,
        view: HomeCareFixtures.helperView(),
        canBuy: false,
      );
      expect(home.shifts.openShiftsAskedFor, [Fixtures.thandiMemberId]);
      await emitOpen(tester, [open(), open(id: 'sams', helperId: 'm-other')]);

      expect(find.text(HomeCareShiftCopy.onShiftTitle), findsOneWidget);
      expect(
        find.widgetWithText(NestButton, HomeCareShiftCopy.endShift),
        findsOneWidget,
      );

      await endIt(tester);
      expect(home.shifts.writes.single.$1, 'endShift');
      expect(home.shifts.writes.single.$2, {
        'shiftId': 'shift-1',
        'by': Fixtures.thandiMemberId,
      });
    });

    testWidgets('a refused end is said in words, above the lock', (
      tester,
    ) async {
      await openLocked(tester);
      await emitOpen(tester, [open()]);
      home.shifts.failWritesWith = const PermissionDeniedFailure();

      await endIt(tester);
      expect(
        find.text(AppCopy.failure(const PermissionDeniedFailure())),
        findsOneWidget,
      );
      expect(find.byType(PremiumLockedView), findsOneWidget);
    });

    testWidgets('with none open, and before the read answers, it is the '
        'locked place and nothing more', (tester) async {
      await openLocked(tester);
      expect(find.text(HomeCareShiftCopy.onNow), findsNothing);
      expect(find.text(HomeCareShiftCopy.endShift), findsNothing);

      await emitOpen(tester, const []);
      expect(find.byType(PremiumLockedView), findsOneWidget);
      expect(find.text(HomeCareShiftCopy.onNow), findsNothing);
      expect(find.text(HomeCareShiftCopy.endShift), findsNothing);
      expect(home.shifts.writes, isEmpty);
    });

    testWidgets('a read that fails leaves the plain locked place', (
      tester,
    ) async {
      await openLocked(tester);
      home.shifts.failOpenShiftsWith(const PermissionDeniedFailure());
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(PremiumLockedView), findsOneWidget);
      expect(find.text(HomeCareShiftCopy.endShift), findsNothing);
      expect(find.text(AppCopy.retry), findsNothing);
    });

    testWidgets('somebody home care is not shared with is asked for nothing', (
      tester,
    ) async {
      await openLocked(
        tester,
        view: HomeCareFixtures.noCleaningView(),
        canBuy: false,
      );
      expect(find.byType(PremiumLockedView), findsOneWidget);
      expect(home.shifts.openShiftsAskedFor, isEmpty);
    });

    testWidgets('nothing is read with shifts switched off', (tester) async {
      home.flagsDefaultOn = false;
      await openLocked(tester);
      expect(find.byType(PremiumLockedView), findsOneWidget);
      expect(home.shifts.openShiftsAskedFor, isEmpty);
    });

    testWidgets('nothing is read until the entitlement is known', (
      tester,
    ) async {
      final entitlements = FakeEntitlementRepository();
      addTearDown(entitlements.close);
      await home.pump(
        tester,
        premium: false,
        also: [
          ChangeNotifierProvider<HouseholdEntitlement>(
            create: (_) => HouseholdEntitlement(
              entitlementRepository: entitlements,
              householdId: Fixtures.householdId,
            ),
          ),
        ],
      );
      await tester.pump();

      expect(find.byType(PremiumLockedView), findsNothing);
      expect(home.shifts.openShiftsAskedFor, isEmpty);
    });

    for (final (who, view) in [
      ('a parent', Fixtures.view),
      ('a helper', HomeCareFixtures.helperView),
    ]) {
      testWidgets('the open shift holds for $who in dark at 200% text on a '
          '360-wide phone', (tester) async {
        tester.view.physicalSize = const Size(360 * 3, 800 * 3);
        tester.view.devicePixelRatio = 3;
        addTearDown(tester.view.reset);

        await openLocked(
          tester,
          view: view(),
          canBuy: who == 'a parent',
          brightness: Brightness.dark,
          textScale: 2,
        );
        await emitOpen(tester, [open()]);
        expect(tester.takeException(), isNull);

        await scrollToEnd(tester);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await tester.tap(find.text(HomeCareShiftCopy.endShift));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      });
    }
  });

  testWidgets('with Premium home care opens', (tester) async {
    await home.pump(tester);
    await tester.pump();

    expect(find.byType(HomeCareScreen), findsOneWidget);
    expect(find.byType(PremiumLockedView), findsNothing);
    expect(home.jobs.jobsAskedFor, isNotEmpty);
  });

  testWidgets('a parent’s See Premium opens the paywall on home care, and '
      'back leaves the locked place', (tester) async {
    final subscriptions = await openLocked(tester);
    expect(find.text(HomeCareCopy.title), findsOneWidget);

    await seePremium(tester);

    expect(find.byType(PaywallPage), findsOneWidget);
    expect(
      subscriptions.paywallOpens.opened.single.trigger,
      PremiumFeature.homeCare,
    );
    await scrollSheetTo(tester, find.text(SubscriptionCopy.subscribe));
    expect(find.text(SubscriptionCopy.askAParent), findsNothing);

    Navigator.of(tester.element(find.byType(PaywallPage))).pop();
    await tester.pumpAndSettle();
    home.router.pop();
    await tester.pumpAndSettle();
    expect(find.byType(PremiumLockedView), findsNothing);
  });

  testWidgets('a helper is shown her jobs locked and told to ask a parent', (
    tester,
  ) async {
    await openLocked(
      tester,
      view: HomeCareFixtures.helperView(),
      canBuy: false,
    );
    expect(find.byType(PremiumLockedView), findsOneWidget);

    await seePremium(tester);

    await scrollSheetTo(tester, find.text(SubscriptionCopy.askAParent));
    expect(find.text(SubscriptionCopy.subscribe), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a carer is shown home care locked and told to ask a parent', (
    tester,
  ) async {
    await openLocked(
      tester,
      view: NannyFixtures.carerView(
        AccessDefaults.carer.withLevel(
          HouseholdArea.homeCare,
          AccessLevel.view,
        ),
      ),
      canBuy: false,
    );
    expect(find.byType(PremiumLockedView), findsOneWidget);

    await seePremium(tester);

    await scrollSheetTo(tester, find.text(SubscriptionCopy.askAParent));
    expect(find.text(SubscriptionCopy.subscribe), findsNothing);
    expect(tester.takeException(), isNull);
  });

  for (final (who, view) in [
    ('a parent', Fixtures.view),
    ('a helper', HomeCareFixtures.helperView),
  ]) {
    testWidgets('locked home care and its paywall hold for $who in dark at '
        '200% text on a 360-wide phone', (tester) async {
      tester.view.physicalSize = const Size(360 * 3, 800 * 3);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);

      await openLocked(
        tester,
        view: view(),
        canBuy: who == 'a parent',
        brightness: Brightness.dark,
        textScale: 2,
      );
      expect(tester.takeException(), isNull);
      expect(find.byType(PremiumLockedView), findsOneWidget);

      await seePremium(tester);
      expect(find.byType(PaywallPage), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
