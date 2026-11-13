import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/design/nest_kit.dart';
import 'package:nestprep/features/subscriptions/model/entitlement.dart';
import 'package:nestprep/features/subscriptions/model/entitlement_status.dart';
import 'package:nestprep/features/subscriptions/ui/premium_lockup.dart';
import 'package:nestprep/shared/copy/subscription_copy.dart';

import '../../../support/premium_entitlement.dart';
import '../../../support/pump_screen.dart';

/// The head of the household's home says Premium beside the wordmark while
/// the household has it, and only then (subscriptions ADR-0007).
void main() {
  const screen = NestScaffold(
    leading: PremiumLockup(),
    trailing: [SizedBox.square(dimension: 44), SizedBox.square(dimension: 44)],
    body: SizedBox.shrink(),
  );

  testWidgets('a free household reads the wordmark alone', (tester) async {
    await pumpScreen(tester, screen, providers: const []);
    await tester.pumpAndSettle();
    expect(find.byType(NestBrandLockup), findsOneWidget);
    expect(find.byType(NestPremiumSeal), findsNothing);
  });

  testWidgets('a Premium household reads the seal beside it', (tester) async {
    await pumpScreen(tester, screen, providers: [premiumEntitlementProvider()]);
    await tester.pumpAndSettle();
    expect(find.text(SubscriptionCopy.premium), findsOneWidget);
  });

  testWidgets('a lapsed household does not', (tester) async {
    await pumpScreen(
      tester,
      screen,
      providers: [
        premiumEntitlementProvider(
          entitlement: Entitlement(
            premiumUntil: DateTime.now().subtract(const Duration(days: 1)),
            status: EntitlementStatus.expired,
          ),
        ),
      ],
    );
    await tester.pumpAndSettle();
    expect(find.byType(NestPremiumSeal), findsNothing);
  });

  testWidgets('it holds at phone width in dark at 200% text', (tester) async {
    tester.view.physicalSize = const Size(360 * 3, 800 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await pumpScreen(
      tester,
      screen,
      providers: [premiumEntitlementProvider()],
      brightness: Brightness.dark,
      textScale: 2,
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text(SubscriptionCopy.premium), findsOneWidget);
  });
}
