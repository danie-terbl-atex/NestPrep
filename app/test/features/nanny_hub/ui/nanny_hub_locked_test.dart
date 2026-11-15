import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/app/nanny_hub_route.dart';
import 'package:nestprep/design/nest_kit.dart';
import 'package:nestprep/features/household/model/access_defaults.dart';
import 'package:nestprep/features/household/model/access_level.dart';
import 'package:nestprep/features/household/model/household_area.dart';
import 'package:nestprep/features/household/model/household_view.dart';
import 'package:nestprep/features/nanny_hub/model/shift.dart';
import 'package:nestprep/features/nanny_hub/ui/nanny_hub_screen.dart';
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
import '../../../support/household_fixtures.dart';
import '../../../support/nanny_fixtures.dart';
import '../../../support/pump_nanny_hub.dart';
import '../../../support/pump_subscriptions.dart';

/// The nanny hub is Premium in full (subscriptions ADR-0008): a household
/// without it meets every one of the hub's addresses locked, never hidden,
/// with nothing behind it listening — whoever opens it, family or not — but
/// for the shifts still open, which it can always end (subscriptions
/// ADR-0009).
void main() {
  late NannyFakes fakes;

  setUp(() => fakes = NannyFakes());
  tearDown(() => fakes.close());

  const id = Fixtures.householdId;
  const kid = Fixtures.kidMemberId;
  final places = {
    'the hub': NannyHubRoute.pathFor(id),
    'a child’s card': NannyHubRoute.childPathFor(id, kid),
    'the emergency sheet': NannyHubRoute.emergencyPathFor(id),
    'the house guide': NannyHubRoute.guidePathFor(id),
    'the house rules': NannyHubRoute.rulesPathFor(id),
    'the checklists': NannyHubRoute.checklistsPathFor(id),
    'a shift': NannyHubRoute.shiftPathFor(id, 'tonight'),
    'a shift’s summary': NannyHubRoute.summaryPathFor(id, 'tonight'),
    'a shift’s photos': NannyHubRoute.photosPathFor(id, 'tonight'),
    'who may collect': NannyHubRoute.pickupsPathFor(id),
    'the door check': NannyHubRoute.pickupCheckPathFor(id, kid),
    'the booked shifts': NannyHubRoute.bookingsPathFor(id),
    'the house codes': NannyHubRoute.codesPathFor(id),
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
    await pumpNannyHub(
      tester,
      fakes,
      location: location,
      view: view,
      premium: false,
      also: subscriptions.providers,
      brightness: brightness,
      textScale: textScale,
    );
    await tester.pump();
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
        find.text(SubscriptionCopy.headline(PremiumFeature.nannyHub)),
        findsOneWidget,
      );
      expect(fakes.hub.cards.hasListener, isFalse);
      expect(fakes.shifts.summaries.hasListener, isFalse);
      expect(fakes.shifts.shift.hasListener, isFalse);
      expect(fakes.shifts.openShifts.hasListener, isTrue);
      expect(fakes.hub.writes, isEmpty);
    });
  }

  group('a shift left open', () {
    Future<void> emitOpen(WidgetTester tester, List<Shift> shifts) async {
      fakes.shifts.openShifts.add(shifts);
      await tester.pumpAndSettle();
    }

    Future<void> endIt(WidgetTester tester) async {
      await scrollTo(tester, find.text(NannyShiftCopy.endShift));
      await tester.tap(find.text(NannyShiftCopy.endShift));
      await tester.pumpAndSettle();
      await tester.tap(find.text(NannyShiftCopy.endShift).last);
      await tester.pumpAndSettle();
    }

    testWidgets('a parent sees the carer still on shift under the lock, and '
        'ends it with no note', (tester) async {
      await openLocked(tester);
      await emitOpen(tester, [NannyFixtures.openShift]);

      expect(find.byType(PremiumLockedView), findsOneWidget);
      expect(find.text(SubscriptionCopy.seePremium), findsOneWidget);
      expect(find.text(NannyShiftCopy.lockedOpenBody), findsOneWidget);
      expect(find.text(NannyFixtures.nomsa.displayName), findsOneWidget);
      expect(
        find.widgetWithText(NestButton, NannyShiftCopy.endShift),
        findsOneWidget,
      );

      await scrollTo(tester, find.text(NannyShiftCopy.endShift));
      await tester.tap(find.text(NannyShiftCopy.endShift));
      await tester.pumpAndSettle();
      expect(
        find.text(
          NannyShiftCopy.lockedEndForTitle(NannyFixtures.nomsa.displayName),
        ),
        findsOneWidget,
      );
      await tester.tap(find.text(NannyCopy.cancel));
      await tester.pumpAndSettle();
      expect(fakes.directory.ended, isEmpty);

      await endIt(tester);
      expect(fakes.directory.ended, [(shiftId: 'shift-1', closingNote: null)]);
      expect(fakes.hub.cards.hasListener, isFalse);
      expect(fakes.shifts.writes, isEmpty);

      await emitOpen(tester, const []);
      expect(find.text(NannyShiftCopy.endShift), findsNothing);
      expect(find.byType(PremiumLockedView), findsOneWidget);
    });

    testWidgets('a carer ends her own, and is not offered anybody else’s', (
      tester,
    ) async {
      await openLocked(tester, view: NannyFixtures.carerView(), canBuy: false);
      await emitOpen(tester, [
        NannyFixtures.openShift,
        NannyFixtures.openShift.copyWith(
          id: 'thandis',
          carerMemberId: Fixtures.thandiMemberId,
        ),
      ]);

      expect(find.text(NannyCopy.onShiftTitle), findsOneWidget);
      expect(find.text(Fixtures.thandi.displayName), findsNothing);
      expect(
        find.widgetWithText(NestButton, NannyShiftCopy.endShift),
        findsOneWidget,
      );

      await endIt(tester);
      expect(fakes.directory.ended, [(shiftId: 'shift-1', closingNote: null)]);
    });

    testWidgets('a carer who may only look is asked for nothing', (
      tester,
    ) async {
      await openLocked(
        tester,
        view: NannyFixtures.lookOnlyCarerView(),
        canBuy: false,
      );
      expect(find.byType(PremiumLockedView), findsOneWidget);
      expect(fakes.shifts.openShifts.hasListener, isFalse);
    });

    testWidgets('a refused end is said in words, above the lock', (
      tester,
    ) async {
      await openLocked(tester);
      await emitOpen(tester, [NannyFixtures.openShift]);
      fakes.directory.failWith = const PermissionDeniedFailure();

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
      expect(find.text(NannyShiftCopy.lockedOpenShifts), findsNothing);
      expect(find.text(NannyShiftCopy.endShift), findsNothing);

      await emitOpen(tester, const []);
      expect(find.byType(PremiumLockedView), findsOneWidget);
      expect(find.text(NannyShiftCopy.lockedOpenShifts), findsNothing);
      expect(find.text(NannyShiftCopy.endShift), findsNothing);
      expect(fakes.directory.ended, isEmpty);
    });

    testWidgets('a read that fails leaves the plain locked place', (
      tester,
    ) async {
      await openLocked(tester);
      fakes.shifts.openShifts.addError(const PermissionDeniedFailure());
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(PremiumLockedView), findsOneWidget);
      expect(find.text(NannyShiftCopy.endShift), findsNothing);
      expect(find.text(AppCopy.retry), findsNothing);
    });

    testWidgets('nothing is read until the entitlement is known', (
      tester,
    ) async {
      final entitlements = FakeEntitlementRepository();
      addTearDown(entitlements.close);
      await pumpNannyHub(
        tester,
        fakes,
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
      expect(fakes.shifts.openShifts.hasListener, isFalse);
    });

    for (final (who, view) in [
      ('a parent', NannyFixtures.parentView),
      ('a carer', NannyFixtures.carerView),
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
        await emitOpen(tester, [NannyFixtures.openShift]);
        expect(tester.takeException(), isNull);

        await scrollTo(tester, find.text(NannyShiftCopy.endShift));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await tester.tap(find.text(NannyShiftCopy.endShift));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      });
    }
  });

  testWidgets('with Premium the hub opens', (tester) async {
    await pumpNannyHub(tester, fakes);
    await tester.pump();

    expect(find.byType(NannyHubScreen), findsOneWidget);
    expect(find.byType(PremiumLockedView), findsNothing);
    expect(fakes.hub.cards.hasListener, isTrue);
  });

  testWidgets('a parent’s See Premium opens the paywall on the nanny hub', (
    tester,
  ) async {
    final subscriptions = await openLocked(tester);
    expect(find.text(NannyCopy.title), findsOneWidget);

    await seePremium(tester);

    expect(find.byType(PaywallPage), findsOneWidget);
    expect(
      subscriptions.paywallOpens.opened.single.trigger,
      PremiumFeature.nannyHub,
    );
    await scrollSheetTo(tester, find.text(SubscriptionCopy.subscribe));
    expect(find.text(SubscriptionCopy.askAParent), findsNothing);
  });

  testWidgets('a carer is shown the hub locked and told to ask a parent', (
    tester,
  ) async {
    await openLocked(tester, view: NannyFixtures.carerView(), canBuy: false);
    expect(find.byType(PremiumLockedView), findsOneWidget);

    await seePremium(tester);

    await scrollSheetTo(tester, find.text(SubscriptionCopy.askAParent));
    expect(find.text(SubscriptionCopy.subscribe), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a helper is shown the hub locked and told to ask a parent', (
    tester,
  ) async {
    await openLocked(
      tester,
      view: Fixtures.helperView(
        AccessDefaults.helper.withLevel(
          HouseholdArea.nannyHub,
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
    ('a parent', NannyFixtures.parentView),
    ('a carer', NannyFixtures.carerView),
  ]) {
    testWidgets('the locked hub and its paywall hold for $who in dark at 200% '
        'text on a 360-wide phone', (tester) async {
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
