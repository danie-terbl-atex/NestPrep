import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/app/household_shell.dart';
import 'package:nestprep/design/nest_kit.dart';
import 'package:nestprep/features/lunch_box/ui/kid_lunch_premium.dart';
import 'package:nestprep/features/lunch_box/ui/lunch_screen.dart';
import 'package:nestprep/features/subscriptions/model/entitlement.dart';
import 'package:nestprep/features/subscriptions/model/premium_feature.dart';
import 'package:nestprep/features/subscriptions/ui/paywall_page.dart';
import 'package:nestprep/shared/copy/app_copy.dart';
import 'package:nestprep/shared/copy/subscription_copy.dart';

import '../../../support/household_fixtures.dart';
import '../../../support/pump_screen.dart';
import '../../../support/pump_subscriptions.dart';

/// Lunch boxes without Premium (subscriptions ADR-0008, ADR-0009): the Food
/// tab's lunch side is shown locked, never hidden, and reads no lunch
/// controller — none is provided here, so a read would throw. A kid device
/// of a free household is told kindly, with nothing to buy.
void main() {
  const feature = PremiumFeature.lunchBox;

  Future<SubscriptionHarness> pumpTab(
    WidgetTester tester, {
    Entitlement entitlement = Entitlement.free,
    Brightness brightness = Brightness.light,
    double textScale = 1,
    Size size = const Size(420, 900),
    ValueChanged<HouseholdTab>? onSelectTab,
  }) async {
    tester.view.physicalSize = size * 3;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final subscriptions = SubscriptionHarness(entitlement: entitlement);
    await pumpScreen(
      tester,
      LunchScreen(onSelectTab: onSelectTab ?? (_) {}),
      providers: subscriptions.providers,
      brightness: brightness,
      textScale: textScale,
    );
    await tester.pumpAndSettle();
    return subscriptions;
  }

  testWidgets('a free household sees lunch boxes locked, with the Food '
      'switch and the tab bar still there', (tester) async {
    HouseholdTab? selected;
    await pumpTab(tester, onSelectTab: (tab) => selected = tab);
    expect(find.text(SubscriptionCopy.headline(feature)), findsOneWidget);
    expect(find.text(SubscriptionCopy.pitch(feature)), findsOneWidget);
    expect(find.byIcon(LucideIcons.lock), findsOneWidget);
    expect(find.byType(HouseholdTabBar), findsOneWidget);
    expect(
      find.widgetWithText(NestChip, HouseholdTab.lunch.label),
      findsOneWidget,
    );
    await tester.tap(find.widgetWithText(NestChip, HouseholdTab.meals.label));
    expect(selected, HouseholdTab.meals);
  });

  testWidgets('See Premium opens the paywall on lunch boxes', (tester) async {
    final subscriptions = await pumpTab(tester);
    await tester.tap(find.text(SubscriptionCopy.seePremium));
    await tester.pumpAndSettle();
    expect(find.byType(PaywallPage), findsOneWidget);
    expect(subscriptions.paywallOpens.opened.single.trigger, feature);
  });

  testWidgets('a household whose Premium lapsed is locked the same way', (
    tester,
  ) async {
    await pumpTab(
      tester,
      entitlement: Entitlement(premiumUntil: DateTime.utc(2020)),
    );
    expect(find.text(SubscriptionCopy.headline(feature)), findsOneWidget);
  });

  testWidgets('the locked tab holds at 360 wide, in dark, at 200% text', (
    tester,
  ) async {
    await pumpTab(
      tester,
      brightness: Brightness.dark,
      textScale: 2,
      size: const Size(360, 640),
    );
    expect(tester.takeException(), isNull);
    expect(find.text(SubscriptionCopy.seePremium), findsOneWidget);
  });

  group('a kid device’s chooser', () {
    Future<void> pumpKid(
      WidgetTester tester, {
      required Entitlement entitlement,
      Brightness brightness = Brightness.light,
      double textScale = 1,
      Size size = const Size(420, 900),
    }) async {
      tester.view.physicalSize = size * 3;
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      await pumpScreen(
        tester,
        const KidLunchPremium(
          householdId: Fixtures.householdId,
          child: Text('the chooser'),
        ),
        providers: SubscriptionHarness(entitlement: entitlement).providers,
        brightness: brightness,
        textScale: textScale,
      );
      await tester.pumpAndSettle();
    }

    testWidgets('of a free household says so kindly, with nothing to buy', (
      tester,
    ) async {
      await pumpKid(tester, entitlement: Entitlement.free);
      expect(find.text('the chooser'), findsNothing);
      expect(find.text(LunchKidPicksCopy.kidLockedTitle), findsOneWidget);
      expect(find.text(LunchKidPicksCopy.kidLockedBody), findsOneWidget);
      expect(find.byIcon(LucideIcons.lock), findsOneWidget);
      expect(find.byType(NestButton), findsNothing);
      expect(find.text(SubscriptionCopy.seePremium), findsNothing);
    });

    testWidgets('of a Premium household opens', (tester) async {
      await pumpKid(
        tester,
        entitlement: Entitlement(premiumUntil: DateTime.utc(2100)),
      );
      expect(find.text('the chooser'), findsOneWidget);
      expect(find.text(LunchKidPicksCopy.kidLockedTitle), findsNothing);
    });

    testWidgets('locked, holds at 360 wide, in dark, at 200% text', (
      tester,
    ) async {
      await pumpKid(
        tester,
        entitlement: Entitlement.free,
        brightness: Brightness.dark,
        textScale: 2,
        size: const Size(360, 640),
      );
      expect(tester.takeException(), isNull);
      expect(find.text(LunchKidPicksCopy.kidLockedTitle), findsOneWidget);
    });
  });
}
