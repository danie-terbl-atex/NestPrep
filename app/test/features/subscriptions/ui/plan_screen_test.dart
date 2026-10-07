import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/household/model/household_view.dart';
import 'package:nestprep/features/subscriptions/model/billing_store.dart';
import 'package:nestprep/features/subscriptions/model/entitlement.dart';
import 'package:nestprep/features/subscriptions/model/entitlement_status.dart';
import 'package:nestprep/features/subscriptions/model/premium_feature.dart';
import 'package:nestprep/features/subscriptions/model/subscription_plan.dart';
import 'package:nestprep/features/subscriptions/state/household_entitlement.dart';
import 'package:nestprep/features/subscriptions/state/plan_controller.dart';
import 'package:nestprep/features/subscriptions/ui/plan_screen.dart';
import 'package:nestprep/features/subscriptions/ui/premium_gate.dart';
import 'package:nestprep/shared/copy/app_copy.dart';
import 'package:nestprep/shared/copy/subscription_copy.dart';
import 'package:nestprep/shared/failure/app_failure.dart';
import 'package:provider/provider.dart';

import '../../../support/fake_link_opener.dart';
import '../../../support/household_fixtures.dart';
import '../../../support/pump_screen.dart';
import '../../../support/pump_subscriptions.dart';

/// Plan and billing (subscriptions ADR-0001): which plan the household is
/// on and what is worth knowing about it, in every state — and the buyer,
/// and only the buyer, sent to their store to change it.
void main() {
  late SubscriptionHarness premium;
  late FakeLinkOpener opener;
  bool? answer;

  final inAMonth = DateTime.now().toUtc().add(const Duration(days: 30));
  final lastWeek = DateTime.now().toUtc().subtract(const Duration(days: 7));

  Entitlement premiumBy(String memberId, {bool willRenew = true}) =>
      Entitlement(
        premiumUntil: inAMonth,
        status: willRenew
            ? EntitlementStatus.active
            : EntitlementStatus.cancelled,
        plan: SubscriptionPlan.yearly,
        store: BillingStore.playStore,
        willRenew: willRenew,
        managedByMemberId: memberId,
      );

  Future<void> pumpPlan(
    WidgetTester tester, {
    Entitlement entitlement = Entitlement.free,
    HouseholdView? view,
    Brightness brightness = Brightness.light,
    double textScale = 1,
  }) async {
    premium = SubscriptionHarness(entitlement: entitlement);
    opener = FakeLinkOpener();
    final household = view ?? Fixtures.view();
    await pumpScreen(
      tester,
      ChangeNotifierProvider(
        create: (_) => PlanController(
          storeBilling: premium.store,
          purchaseCoordinator: premium.coordinator,
          linkOpener: opener,
          viewerMemberId: household.viewerMember?.id,
        ),
        child: const PlanScreen(),
      ),
      providers: premium.providers,
      view: household,
      brightness: brightness,
      textScale: textScale,
    );
    await tester.pumpAndSettle();
  }

  Future<void> scrollTo(WidgetTester tester, Finder finder) =>
      tester.scrollUntilVisible(finder, 200);

  testWidgets('a free household sees what it has, and the way to premium', (
    tester,
  ) async {
    await pumpPlan(tester);
    expect(find.text(SubscriptionCopy.free), findsOneWidget);
    expect(find.text(SubscriptionCopy.freeSummary), findsOneWidget);
    await scrollTo(tester, find.text(SubscriptionCopy.upgrade));
    await tester.tap(find.text(SubscriptionCopy.upgrade));
    await tester.pumpAndSettle();
    expect(
      find.text(SubscriptionCopy.headline(PremiumFeature.direct)),
      findsOneWidget,
    );
  });

  testWidgets('a premium household sees when it renews and who bought it', (
    tester,
  ) async {
    await pumpPlan(tester, entitlement: premiumBy(Fixtures.samMemberId));
    expect(find.text(SubscriptionCopy.premium), findsOneWidget);
    expect(find.textContaining('Renews on'), findsOneWidget);
    expect(
      find.text(
        SubscriptionCopy.managedBy('Sam Parent', BillingStore.playStore),
      ),
      findsOneWidget,
    );
    expect(find.text(SubscriptionCopy.upgrade), findsNothing);
  });

  testWidgets('the buyer is sent to their own store to change it', (
    tester,
  ) async {
    await pumpPlan(tester, entitlement: premiumBy(Fixtures.samMemberId));
    await scrollTo(tester, find.text(SubscriptionCopy.manage));
    await tester.tap(find.text(SubscriptionCopy.manage));
    await tester.pump();
    expect(opener.opened.single.host, 'play.google.com');
  });

  testWidgets('anybody else is told who can change it, and handed no button', (
    tester,
  ) async {
    await pumpPlan(tester, entitlement: premiumBy(Fixtures.thandiMemberId));
    await scrollTo(
      tester,
      find.text(SubscriptionCopy.onlyBuyerManages('Thandi Helper')),
    );
    expect(find.text(SubscriptionCopy.manage), findsNothing);
  });

  testWidgets('a subscription that will not renew says when it ends', (
    tester,
  ) async {
    await pumpPlan(
      tester,
      entitlement: premiumBy(Fixtures.samMemberId, willRenew: false),
    );
    expect(find.textContaining('Ends on'), findsOneWidget);
  });

  testWidgets('a lapsed household is told nothing it made has gone', (
    tester,
  ) async {
    await pumpPlan(
      tester,
      entitlement: Entitlement(
        premiumUntil: lastWeek,
        status: EntitlementStatus.expired,
        plan: SubscriptionPlan.monthly,
        store: BillingStore.playStore,
        managedByMemberId: Fixtures.samMemberId,
      ),
    );
    expect(find.text(SubscriptionCopy.free), findsOneWidget);
    expect(find.text(SubscriptionCopy.lapsed), findsOneWidget);
    expect(find.text(SubscriptionCopy.keptSafe), findsOneWidget);
  });

  testWidgets(
    'a payment the store is retrying says premium carries on meanwhile',
    (tester) async {
      await pumpPlan(
        tester,
        entitlement: premiumBy(
          Fixtures.samMemberId,
        ).copyWith(status: EntitlementStatus.inGracePeriod),
      );
      expect(
        find.textContaining('couldn’t take the last payment'),
        findsOneWidget,
      );
    },
  );

  testWidgets('restoring with nothing to restore says so in words', (
    tester,
  ) async {
    await pumpPlan(tester);
    await scrollTo(tester, find.text(SubscriptionCopy.restore));
    await tester.tap(find.text(SubscriptionCopy.restore));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pumpAndSettle();
    expect(premium.store.restores, 1);
    await scrollTo(
      tester,
      find.text(SubscriptionCopy.problem(SubscriptionProblem.nothingToRestore)),
    );
  });

  testWidgets('a helper sees the plan and who can buy it, and no purchase', (
    tester,
  ) async {
    await pumpPlan(tester, view: Fixtures.view(viewerUid: Fixtures.thandiUid));
    expect(find.text(SubscriptionCopy.askAParent), findsOneWidget);
    expect(find.text(SubscriptionCopy.upgrade), findsNothing);
    expect(find.text(SubscriptionCopy.restore), findsNothing);
  });

  testWidgets('a failed read says why and reads again on retry', (
    tester,
  ) async {
    await pumpPlan(tester);
    premium.entitlements.fail(const UnavailableFailure());
    await tester.pumpAndSettle();
    expect(
      find.text(AppCopy.failure(const UnavailableFailure())),
      findsOneWidget,
    );
    await tester.tap(find.text(AppCopy.retry));
    await tester.pumpAndSettle();
    expect(find.text(SubscriptionCopy.free), findsOneWidget);
  });

  testWidgets('survives dark at 200% text on a 360-wide phone', (tester) async {
    tester.view.physicalSize = const Size(360 * 3, 800 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await pumpPlan(
      tester,
      entitlement: premiumBy(Fixtures.thandiMemberId),
      brightness: Brightness.dark,
      textScale: 2,
    );
    await scrollTo(tester, find.text(SubscriptionCopy.restore));
    expect(tester.takeException(), isNull);
  });

  group('ensurePremium — the one call a premium feature makes', () {
    Future<void> pumpGate(WidgetTester tester, Entitlement entitlement) async {
      premium = SubscriptionHarness(entitlement: entitlement);
      await pumpScreen(
        tester,
        Builder(
          builder: (context) {
            // A premium feature's screen sits under the household shell,
            // whose listener has long since read the entitlement.
            context.watch<HouseholdEntitlement>();
            return TextButton(
              onPressed: () async => answer = await ensurePremium(
                context,
                feature: PremiumFeature.prepList,
              ),
              child: const Text('Prep list'),
            );
          },
        ),
        providers: premium.providers,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Prep list'));
      await tester.pumpAndSettle();
    }

    testWidgets('lets a premium household straight in', (tester) async {
      await pumpGate(tester, premiumBy(Fixtures.samMemberId));
      expect(answer, isTrue);
      expect(premium.server.offersAsked, 0);
    });

    testWidgets('offers premium, on that feature, to a free household', (
      tester,
    ) async {
      answer = null;
      await pumpGate(tester, Entitlement.free);
      expect(
        find.text(SubscriptionCopy.headline(PremiumFeature.prepList)),
        findsOneWidget,
      );
      expect(answer, isNull);
    });
  });
}
