import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/subscriptions/model/premium_feature.dart';
import 'package:nestprep/features/subscriptions/model/subscription_offer.dart';
import 'package:nestprep/features/subscriptions/model/subscription_plan.dart';
import 'package:nestprep/features/subscriptions/ui/paywall_sheet.dart';
import 'package:nestprep/shared/copy/app_copy.dart';
import 'package:nestprep/shared/copy/subscription_copy.dart';
import 'package:nestprep/shared/failure/app_failure.dart';

import '../../../support/fake_subscriptions.dart';
import '../../../support/pump_screen.dart';
import '../../../support/pump_subscriptions.dart';

/// The paywall (subscriptions ADR-0001) in all four states, with the store's
/// own prices, the purchase carried to the server before anything is
/// promised, and never a store's own error words (`FE-08`, `FE-09`).
void main() {
  late SubscriptionHarness premium;
  bool? answer;

  const openLabel = 'Open the paywall';

  Future<void> pumpHost(
    WidgetTester tester, {
    PremiumFeature feature = PremiumFeature.additionalChild,
    Brightness brightness = Brightness.light,
    double textScale = 1,
  }) async {
    answer = null;
    await pumpScreen(
      tester,
      Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: TextButton(
              onPressed: () async =>
                  answer = await showPaywall(context, feature: feature),
              child: const Text(openLabel),
            ),
          ),
        ),
      ),
      providers: premium.providers,
      brightness: brightness,
      textScale: textScale,
    );
    await tester.tap(find.text(openLabel));
    await tester.pumpAndSettle();
  }

  Future<void> scrollTo(WidgetTester tester, Finder finder) =>
      tester.scrollUntilVisible(
        finder,
        200,
        scrollable: find.byType(Scrollable).last,
      );

  // Made inside each test rather than in `setUp`: the store's stream has to
  // belong to the test's own fake-async zone, or what it reports is never
  // delivered while the test pumps.
  void paywallTest(String name, Future<void> Function(WidgetTester) body) =>
      testWidgets(name, (tester) async {
        premium = SubscriptionHarness();
        await body(tester);
      });

  paywallTest(
    'opens on the feature reached for, with both plans at the store’s prices',
    (tester) async {
      await pumpHost(tester);

      expect(
        find.text(SubscriptionCopy.headline(PremiumFeature.additionalChild)),
        findsOneWidget,
      );
      await scrollTo(tester, find.text(r'R599.99'));
      expect(find.text(r'R59.99'), findsOneWidget);
      expect(find.text(SubscriptionCopy.saving(16)), findsOneWidget);
    },
  );

  paywallTest('buys the chosen plan, verifies it, and says so warmly', (
    tester,
  ) async {
    await pumpHost(tester);
    await scrollTo(
      tester,
      find.text(SubscriptionCopy.planName(SubscriptionPlan.monthly)),
    );
    await tester.tap(
      find.text(SubscriptionCopy.planName(SubscriptionPlan.monthly)),
    );
    await tester.pump();
    await scrollTo(tester, find.text(SubscriptionCopy.subscribe));
    await tester.tap(find.text(SubscriptionCopy.subscribe));
    await tester.pump();
    expect(premium.store.bought, [FakeStoreBilling.monthly]);

    premium.store.report([purchased(productId: 'nestprep_premium_monthly')]);
    await tester.pumpAndSettle();

    expect(
      premium.server.verified.single.trigger,
      PremiumFeature.additionalChild,
    );
    expect(find.text(SubscriptionCopy.welcomeTitle), findsOneWidget);
    await tester.tap(find.text(SubscriptionCopy.done));
    await tester.pumpAndSettle();
    expect(answer, isTrue);
  });

  paywallTest('holds the button while the server checks the purchase', (
    tester,
  ) async {
    premium.server.holdVerify = Completer<void>();
    await pumpHost(tester);
    await scrollTo(tester, find.text(SubscriptionCopy.subscribe));
    await tester.tap(find.text(SubscriptionCopy.subscribe));
    premium.store.report([purchased()]);
    await tester.pump();
    await tester.pump();

    expect(find.text(SubscriptionCopy.unlocking), findsOneWidget);
    premium.server.holdVerify!.complete();
    await tester.pumpAndSettle();
    expect(find.text(SubscriptionCopy.welcomeTitle), findsOneWidget);
  });

  paywallTest(
    'a verification that fails is said in our words, and the purchase is kept',
    (tester) async {
      premium.server.failVerifyWith = const SubscriptionFailure(
        SubscriptionProblem.storeUnreachable,
      );
      await pumpHost(tester);
      await scrollTo(tester, find.text(SubscriptionCopy.subscribe));
      await tester.tap(find.text(SubscriptionCopy.subscribe));
      premium.store.report([purchased()]);
      await tester.pumpAndSettle();

      expect(
        find.text(
          SubscriptionCopy.problem(SubscriptionProblem.storeUnreachable),
        ),
        findsOneWidget,
      );
      expect(premium.store.finished, isEmpty);
    },
  );

  paywallTest(
    'says plainly that premium is not on sale yet — and it is not an error',
    (tester) async {
      premium.server.answer = SubscriptionOffer.unavailable;
      await pumpHost(tester);
      await scrollTo(tester, find.text(SubscriptionCopy.notYetTitle));
      expect(find.text(SubscriptionCopy.notYetBody), findsOneWidget);
      expect(find.text(SubscriptionCopy.subscribe), findsNothing);
    },
  );

  paywallTest('tells a helper who can buy it, and offers no button', (
    tester,
  ) async {
    premium.server.answer = const SubscriptionOffer(
      isAvailable: true,
      canBuy: false,
      cohort: 'a',
      featuredPlan: SubscriptionPlan.yearly,
      productIds: {SubscriptionPlan.yearly: 'nestprep_premium_yearly'},
    );
    await pumpHost(tester, feature: PremiumFeature.lunchLearning);
    await scrollTo(tester, find.text(SubscriptionCopy.askAParent));
    expect(find.text(SubscriptionCopy.subscribe), findsNothing);
  });

  paywallTest('a failed load says why in words and loads again on retry', (
    tester,
  ) async {
    premium.server.failOfferWith = const UnavailableFailure();
    await pumpHost(tester);
    await scrollTo(tester, find.text(AppCopy.retry));
    expect(
      find.text(AppCopy.failure(const UnavailableFailure())),
      findsOneWidget,
    );
    await tester.tap(find.text(AppCopy.retry));
    await tester.pumpAndSettle();
    expect(premium.server.offersAsked, 2);
    await scrollTo(tester, find.text(SubscriptionCopy.subscribe));
  });

  paywallTest('restores an earlier purchase without counting it as a sale', (
    tester,
  ) async {
    await pumpHost(tester);
    await scrollTo(tester, find.text(SubscriptionCopy.restore));
    await tester.tap(find.text(SubscriptionCopy.restore));
    await tester.pump();
    premium.store.report([purchased(isRestore: true)]);
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pumpAndSettle();

    expect(premium.server.verified.single.trigger, isNull);
    expect(find.text(SubscriptionCopy.welcomeTitle), findsOneWidget);
  });

  paywallTest('closing it without buying answers no', (tester) async {
    await pumpHost(tester);
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();
    expect(answer, isFalse);
  });

  paywallTest('survives dark at 200% text on a 360-wide phone', (tester) async {
    tester.view.physicalSize = const Size(360 * 3, 800 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await pumpHost(tester, brightness: Brightness.dark, textScale: 2);
    await scrollTo(tester, find.text(SubscriptionCopy.restore));
    expect(tester.takeException(), isNull);
  });
}
