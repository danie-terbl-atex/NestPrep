import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/design/nest_kit.dart';
import 'package:nestprep/features/subscriptions/model/premium_feature.dart';
import 'package:nestprep/features/subscriptions/ui/paywall_page.dart';
import 'package:nestprep/features/today/ui/today_lunch_section.dart';
import 'package:nestprep/shared/copy/app_copy.dart';
import 'package:nestprep/shared/copy/subscription_copy.dart';

import '../../../support/lunch_harness.dart';
import '../../../support/pump_screen.dart';
import '../../../support/pump_subscriptions.dart';

/// Today's lunch section without Premium (subscriptions ADR-0009): lunch
/// boxes shown locked in place of the children's boxes, reading no lunch
/// controller — none is provided to the free household here, so a read would
/// throw.
void main() {
  const feature = PremiumFeature.lunchBox;

  Future<SubscriptionHarness> pumpFree(
    WidgetTester tester, {
    Brightness brightness = Brightness.light,
    double textScale = 1,
    VoidCallback? onOpen,
  }) async {
    tester.view.physicalSize = const Size(360 * 3, 800 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final subscriptions = SubscriptionHarness();
    await pumpScreen(
      tester,
      Scaffold(
        body: ListView(children: [TodayLunchSection(onOpen: onOpen ?? () {})]),
      ),
      providers: subscriptions.providers,
      brightness: brightness,
      textScale: textScale,
    );
    await tester.pumpAndSettle();
    return subscriptions;
  }

  testWidgets('a free household sees lunch boxes locked, not hidden', (
    tester,
  ) async {
    await pumpFree(tester);
    expect(find.text(TodayCopy.lunchEyebrow.toUpperCase()), findsOneWidget);
    expect(find.text(SubscriptionCopy.headline(feature)), findsOneWidget);
    expect(find.text(SubscriptionCopy.lockedHint), findsOneWidget);
    expect(find.byIcon(LucideIcons.lock), findsOneWidget);
    expect(find.text(TodayCopy.seeAll), findsNothing);
  });

  testWidgets('the locked card opens the paywall on lunch boxes, and not the '
      'lunch tab', (tester) async {
    var opened = 0;
    final subscriptions = await pumpFree(tester, onOpen: () => opened++);
    await tester.tap(find.text(SubscriptionCopy.headline(feature)));
    await tester.pumpAndSettle();
    expect(find.byType(PaywallPage), findsOneWidget);
    expect(subscriptions.paywallOpens.opened.single.trigger, feature);
    expect(opened, 0);
  });

  testWidgets('the locked card holds at 360 wide, in dark, at 200% text', (
    tester,
  ) async {
    await pumpFree(tester, brightness: Brightness.dark, textScale: 2);
    expect(tester.takeException(), isNull);
    expect(find.text(SubscriptionCopy.headline(feature)), findsOneWidget);
  });

  testWidgets('a Premium household sees its children’s boxes, unlocked', (
    tester,
  ) async {
    final lunch = LunchHarness();
    addTearDown(lunch.close);
    await pumpScreen(
      tester,
      Scaffold(
        body: ListView(children: [TodayLunchSection(onOpen: () {})]),
      ),
      providers: lunch.providers,
    );
    lunch.emit();
    await tester.pumpAndSettle();
    expect(find.text(TodayCopy.seeAll), findsOneWidget);
    expect(find.text(TodayCopy.nothingPacked), findsWidgets);
    expect(find.byIcon(LucideIcons.lock), findsNothing);
  });
}
