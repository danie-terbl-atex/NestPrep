import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/household/data/household_repository.dart';
import 'package:nestprep/features/household/model/household_view.dart';
import 'package:nestprep/features/subscriptions/model/billing_store.dart';
import 'package:nestprep/features/subscriptions/model/entitlement.dart';
import 'package:nestprep/features/subscriptions/model/entitlement_status.dart';
import 'package:nestprep/features/subscriptions/model/grant_days_waiting.dart';
import 'package:nestprep/features/subscriptions/model/grant_source.dart';
import 'package:nestprep/features/subscriptions/model/premium_voucher.dart';
import 'package:nestprep/features/subscriptions/state/plan_controller.dart';
import 'package:nestprep/features/subscriptions/ui/plan_screen.dart';
import 'package:nestprep/shared/copy/premium_voucher_copy.dart';
import 'package:nestprep/shared/copy/subscription_copy.dart';
import 'package:nestprep/shared/flags/feature_flags_controller.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

import '../../../support/fake_feature_flag_source.dart';
import '../../../support/fake_household.dart';
import '../../../support/fake_link_opener.dart';
import '../../../support/fake_premium_vouchers.dart';
import '../../../support/household_fixtures.dart';
import '../../../support/pump_screen.dart';
import '../../../support/pump_subscriptions.dart';

/// Plan & billing with Premium from more than the store (subscriptions
/// ADR-0002 to ADR-0004): the time by where it came from, never frame or
/// gifted time called referral time, and the way to Premium waiting for the
/// signed-in account.
void main() {
  late SubscriptionHarness premium;

  final inAMonth = DateTime.now().toUtc().add(const Duration(days: 30));
  final inFourMonths = DateTime.now().toUtc().add(const Duration(days: 123));

  Future<void> pumpPlan(
    WidgetTester tester, {
    Entitlement entitlement = Entitlement.free,
    List<PremiumVoucher> waiting = const [],
    HouseholdView? view,
    bool vouchersOn = true,
    Brightness brightness = Brightness.light,
    double textScale = 1,
  }) async {
    premium = SubscriptionHarness(entitlement: entitlement);
    premium.vouchers.waiting = [...waiting];
    premium.inbox.attach(Fixtures.samUid);
    final households = FakeHouseholdRepository();
    addTearDown(households.close);
    final household = view ?? Fixtures.view();
    await pumpScreen(
      tester,
      ChangeNotifierProvider(
        create: (_) => PlanController(
          storeBilling: premium.store,
          purchaseCoordinator: premium.coordinator,
          linkOpener: FakeLinkOpener(),
          viewerMemberId: household.viewerMember?.id,
        ),
        child: const PlanScreen(),
      ),
      providers: <SingleChildWidget>[
        ...premium.providers,
        Provider<HouseholdRepository>.value(value: households),
        if (!vouchersOn)
          ChangeNotifierProvider<FeatureFlagsController>(
            create: (_) => FeatureFlagsController(
              source: FakeFeatureFlagSource(),
              defaultOn: false,
            ),
          ),
      ],
      view: household,
      brightness: brightness,
      textScale: textScale,
    );
    await tester.pumpAndSettle();
  }

  Future<void> scrollTo(WidgetTester tester, Finder finder) async {
    await tester.scrollUntilVisible(finder, 200);
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -200));
    await tester.pumpAndSettle();
  }

  Entitlement paidWith(GrantDaysWaiting waiting) => Entitlement(
    premiumUntil: inFourMonths,
    storeUntil: inAMonth,
    status: EntitlementStatus.active,
    store: BillingStore.playStore,
    willRenew: false,
    managedByMemberId: Fixtures.samMemberId,
    referralDaysWaiting: waiting.total,
    grantUntil: inFourMonths,
    grantDaysWaiting: waiting,
  );

  testWidgets('says each kind of free time waiting, by where it came from', (
    tester,
  ) async {
    await pumpPlan(
      tester,
      entitlement: paidWith(
        const GrantDaysWaiting(referral: 30, frame: 93, code: 30),
      ),
    );
    expect(find.text(PremiumVoucherCopy.timeTitle), findsOneWidget);
    expect(find.text(PremiumVoucherCopy.paidPlan), findsOneWidget);
    expect(find.text('1 free month waiting'), findsOneWidget);
    expect(find.text('3 months waiting'), findsOneWidget);
    expect(find.text('30 days waiting'), findsOneWidget);
    expect(
      find.text(PremiumVoucherCopy.sourceTitle(GrantSource.frame)),
      findsOneWidget,
    );
    expect(find.text(PremiumVoucherCopy.waitsForPaid), findsOneWidget);
    expect(find.textContaining('4 months'), findsNothing);
  });

  testWidgets('frame months alone are never called referral months', (
    tester,
  ) async {
    await pumpPlan(
      tester,
      entitlement: paidWith(const GrantDaysWaiting(frame: 93)),
    );
    expect(find.text('3 months waiting'), findsOneWidget);
    expect(
      find.text(PremiumVoucherCopy.sourceTitle(GrantSource.referral)),
      findsNothing,
    );
    expect(find.textContaining('free month'), findsNothing);
    expect(find.textContaining('referral'), findsNothing);
  });

  testWidgets('frame time that is not whole months reads in days', (
    tester,
  ) async {
    await pumpPlan(
      tester,
      entitlement: paidWith(const GrantDaysWaiting(frame: 100)),
    );
    expect(find.text('100 days waiting'), findsOneWidget);
  });

  testWidgets('an older server’s referral days still read as referral time', (
    tester,
  ) async {
    await pumpPlan(
      tester,
      entitlement: paidWith(const GrantDaysWaiting(referral: 60))
          .copyWith(grantDaysWaiting: null),
    );
    expect(find.text('2 free months waiting'), findsOneWidget);
  });

  testWidgets('free Premium running now is not a referral month', (
    tester,
  ) async {
    await pumpPlan(
      tester,
      entitlement: Entitlement(
        premiumUntil: inAMonth,
        grantUntil: inFourMonths,
        grantDaysWaiting: const GrantDaysWaiting(frame: 62),
      ),
    );
    expect(find.textContaining('Free Premium until'), findsOneWidget);
    expect(find.text(PremiumVoucherCopy.freePremium), findsOneWidget);
    expect(find.text('2 months waiting'), findsOneWidget);
    expect(find.textContaining('referral'), findsNothing);
  });

  testWidgets('no free time waiting shows no time card', (tester) async {
    await pumpPlan(tester);
    expect(find.text(PremiumVoucherCopy.timeTitle), findsNothing);
  });

  testWidgets('Premium waiting for the account opens the claim sheet', (
    tester,
  ) async {
    await pumpPlan(tester, waiting: [FakePremiumVoucherDirectory.frame]);
    final entry = find.byKey(const ValueKey('plan-premium-waiting'));
    await scrollTo(tester, entry);
    expect(
      find.text('3 months of Premium from your frame order'),
      findsOneWidget,
    );
    await tester.tap(entry);
    await tester.pumpAndSettle();
    expect(find.text(PremiumVoucherCopy.addTo('The Parkers')), findsOneWidget);
  });

  testWidgets('a different email can be proven from here', (tester) async {
    await pumpPlan(tester);
    final link = find.byKey(const ValueKey('plan-different-email'));
    await scrollTo(tester, link);
    expect(find.byKey(const ValueKey('plan-premium-waiting')), findsNothing);
    await tester.tap(link);
    await tester.pumpAndSettle();
    expect(find.text(PremiumVoucherCopy.differentEmailBody), findsOneWidget);
  });

  testWidgets('switched off, or for a helper, there is no way in', (
    tester,
  ) async {
    await pumpPlan(
      tester,
      vouchersOn: false,
      waiting: [FakePremiumVoucherDirectory.frame],
    );
    expect(find.byKey(const ValueKey('plan-different-email')), findsNothing);
    expect(find.byKey(const ValueKey('plan-premium-waiting')), findsNothing);
  });

  testWidgets('a helper is not offered it', (tester) async {
    await pumpPlan(
      tester,
      view: Fixtures.view(viewerUid: Fixtures.thandiUid),
      waiting: [FakePremiumVoucherDirectory.frame],
    );
    expect(find.text(SubscriptionCopy.askAParent), findsOneWidget);
    expect(find.byKey(const ValueKey('plan-different-email')), findsNothing);
  });

  testWidgets('survives dark at 200% text on a 360-wide phone', (tester) async {
    tester.view.physicalSize = const Size(360 * 3, 800 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await pumpPlan(
      tester,
      entitlement: paidWith(
        const GrantDaysWaiting(referral: 30, frame: 93, code: 30),
      ),
      waiting: [FakePremiumVoucherDirectory.frame],
      brightness: Brightness.dark,
      textScale: 2,
    );
    await scrollTo(tester, find.byKey(const ValueKey('plan-different-email')));
    expect(tester.takeException(), isNull);
  });
}
