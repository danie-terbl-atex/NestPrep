import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:nestprep/app/household_route.dart';
import 'package:nestprep/app/household_shell.dart';
import 'package:nestprep/app/referral_routes.dart';
import 'package:nestprep/app/subscription_routes.dart';
import 'package:nestprep/features/household/model/household.dart';
import 'package:nestprep/features/household/model/household_view.dart';
import 'package:nestprep/features/household/state/household_controller.dart';
import 'package:nestprep/features/household/state/invite_step_controller.dart';
import 'package:nestprep/features/household/ui/household_more_screen.dart';
import 'package:nestprep/features/household/ui/invite_step_screen.dart';
import 'package:nestprep/features/referrals/model/household_referral.dart';
import 'package:nestprep/features/subscriptions/model/premium_feature.dart';
import 'package:nestprep/features/subscriptions/ui/paywall_sheet.dart';
import 'package:nestprep/shared/copy/app_copy.dart';
import 'package:nestprep/shared/copy/subscription_copy.dart';
import 'package:nestprep/shared/links/external_link_opener.dart';
import 'package:provider/provider.dart';

import '../../../support/fake_household.dart';
import '../../../support/fake_link_opener.dart';
import '../../../support/household_fixtures.dart';
import '../../../support/pump_referrals.dart';
import '../../../support/pump_screen.dart';
import '../../../support/pump_subscriptions.dart';

/// Give a month, get a month is reachable — from More, the
/// invite step, the paywall and the plan screen — by family, while it is
/// switched on, and back comes back (`FE-17`, subscriptions ADR-0002). A
/// capability with no way in is not done (the vault lesson).
void main() {
  late ReferralHarness referrals;
  late SubscriptionHarness premium;

  Future<void> pumpHousehold(
    WidgetTester tester, {
    required String viewerUid,
    bool isOn = true,
  }) async {
    tester.view.physicalSize = const Size(420 * 3, 1800 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    referrals = ReferralHarness(
      referral: const HouseholdReferral(code: 'ABCD2345'),
      isOn: isOn,
    );
    premium = SubscriptionHarness();
    final households = FakeHouseholdRepository();
    final controller = HouseholdController(
      householdRepository: households,
      householdDirectory: FakeHouseholdDirectory(),
      householdId: Fixtures.householdId,
      viewerUid: viewerUid,
    );
    addTearDown(() async {
      controller.dispose();
      await households.close();
    });
    await pumpRouter(
      tester,
      router: GoRouter(
        initialLocation: HouseholdRoute.pathFor(
          Fixtures.householdId,
          HouseholdTab.more,
        ),
        routes: [
          GoRoute(
            path: '${HouseholdRoute.path}/${HouseholdTab.more.segment}',
            builder: (context, state) =>
                HouseholdMoreScreen(onSelectTab: (_) {}),
          ),
          subscriptionRoute(),
          referralRoute(),
        ],
      ),
      view: Fixtures.view(viewerUid: viewerUid),
      providers: [
        ChangeNotifierProvider<HouseholdController>.value(value: controller),
        Provider<ExternalLinkOpener>.value(value: FakeLinkOpener()),
        ...premium.providers,
        ...referrals.providers,
      ],
    );
    households.emitHousehold(Fixtures.household());
    households.emitMembers([Fixtures.sam, Fixtures.thandi, Fixtures.kid]);
    await tester.pumpAndSettle();
  }

  testWidgets('More is a way in, and back comes back', (tester) async {
    await pumpHousehold(tester, viewerUid: Fixtures.samUid);
    await tester.ensureVisible(find.text(ReferralCopy.openFromHousehold));
    await tester.pumpAndSettle();
    await tester.tap(find.text(ReferralCopy.openFromHousehold));
    await tester.pumpAndSettle();

    expect(find.text(ReferralCopy.heroTitle), findsOneWidget);
    expect(find.text('ABCD2345'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();
    expect(find.text(MoreCopy.subtitle), findsOneWidget);
  });

  testWidgets('nobody is offered it while it is switched off', (tester) async {
    await pumpHousehold(tester, viewerUid: Fixtures.samUid, isOn: false);
    expect(find.text(ReferralCopy.openFromHousehold), findsNothing);
  });

  testWidgets('a helper, who does not refer, is not offered it', (
    tester,
  ) async {
    await pumpHousehold(tester, viewerUid: Fixtures.thandiUid);
    expect(find.text(ReferralCopy.openFromHousehold), findsNothing);
  });

  testWidgets('the plan screen mentions it, and it opens from there', (
    tester,
  ) async {
    await pumpHousehold(tester, viewerUid: Fixtures.samUid);
    await tester.ensureVisible(find.text(SubscriptionCopy.openFromHousehold));
    await tester.pumpAndSettle();
    await tester.tap(find.text(SubscriptionCopy.openFromHousehold));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text(ReferralCopy.mentionBody), 200);
    await tester.tap(find.text(ReferralCopy.mentionBody));
    await tester.pumpAndSettle();
    expect(find.text(ReferralCopy.heroTitle), findsOneWidget);
  });

  testWidgets('the paywall mentions it, and the sheet closes onto it', (
    tester,
  ) async {
    await pumpHousehold(tester, viewerUid: Fixtures.samUid);
    final context = tester.element(find.byType(HouseholdMoreScreen));
    final answer = showPaywall(context, feature: PremiumFeature.prepList);
    await tester.pumpAndSettle();
    expect(premium.paywallOpens.opened.single.trigger, PremiumFeature.prepList);
    await tester.scrollUntilVisible(
      find.text(ReferralCopy.mentionBody),
      200,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(find.text(ReferralCopy.mentionBody));
    await tester.pumpAndSettle();
    expect(await answer, isFalse);
    expect(find.text(ReferralCopy.heroTitle), findsOneWidget);
  });

  testWidgets('the invite step mentions it to a new household', (tester) async {
    tester.view.physicalSize = const Size(420 * 3, 1800 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    referrals = ReferralHarness(
      referral: const HouseholdReferral(code: 'ABCD2345'),
    );
    final households = FakeHouseholdRepository();
    final controller = InviteStepController(
      householdRepository: households,
      householdDirectory: FakeHouseholdDirectory(),
      inviteSharer: referrals.sharer,
      householdId: Fixtures.householdId,
      householdName: 'The Parkers',
      coloursInUse: const [],
    );
    addTearDown(() async {
      controller.dispose();
      await households.close();
    });
    await pumpRouter(
      tester,
      router: GoRouter(
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => const InviteStepScreen(),
          ),
          referralRoute(),
        ],
      ),
      providers: [
        ChangeNotifierProvider<InviteStepController>.value(value: controller),
        ...referrals.providers,
      ],
      view: HouseholdView(
        household: Fixtures.household().copyWith(
          pendingSetupStep: Household.invitePeopleStep,
        ),
        members: [Fixtures.sam],
        viewerUid: Fixtures.samUid,
      ),
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text(ReferralCopy.mentionBody), 200);
    await tester.tap(find.text(ReferralCopy.mentionBody));
    await tester.pumpAndSettle();
    expect(find.text(ReferralCopy.heroTitle), findsOneWidget);
  });
}
