import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/subscriptions/model/plan_choice.dart';
import 'package:nestprep/features/subscriptions/model/store_product.dart';
import 'package:nestprep/features/subscriptions/model/subscription_plan.dart';

import '../../../support/fake_subscriptions.dart';

/// The only sums premium does: which plan to show first, and what a year
/// saves — as a proportion of two store prices, never a price of its own
/// (`ENG-20`, subscriptions ADR-0001).
void main() {
  group('PlanChoice', () {
    test(
      'lists monthly before yearly whatever order the store answered in',
      () {
        final choice = PlanChoice(
          products: const [FakeStoreBilling.yearly, FakeStoreBilling.monthly],
          featured: SubscriptionPlan.yearly,
        );
        expect(choice.products.map((p) => p.plan), SubscriptionPlan.values);
        expect(choice.initialPlan, SubscriptionPlan.yearly);
      },
    );

    test('says what a year saves against twelve months, rounded down', () {
      final choice = PlanChoice(
        products: const [FakeStoreBilling.monthly, FakeStoreBilling.yearly],
        featured: SubscriptionPlan.yearly,
      );
      // 12 × 59.99 = 719.88 against 599.99: 16.65%.
      expect(choice.yearlySavingPercent, 16);
    });

    test('claims no saving across two currencies, or when there is none', () {
      const dollars = StoreProduct(
        productId: 'nestprep_premium_yearly',
        plan: SubscriptionPlan.yearly,
        displayPrice: r'$39.99',
        priceMicros: 39990000,
        currencyCode: 'USD',
      );
      expect(
        PlanChoice(
          products: const [FakeStoreBilling.monthly, dollars],
          featured: SubscriptionPlan.yearly,
        ).yearlySavingPercent,
        isNull,
      );
      const dear = StoreProduct(
        productId: 'nestprep_premium_yearly',
        plan: SubscriptionPlan.yearly,
        displayPrice: r'R999.99',
        priceMicros: 999990000,
        currencyCode: 'ZAR',
      );
      expect(
        PlanChoice(
          products: const [FakeStoreBilling.monthly, dear],
          featured: SubscriptionPlan.yearly,
        ).yearlySavingPercent,
        isNull,
      );
    });

    test(
      'opens on whichever plan exists when the suggested one is missing',
      () {
        final choice = PlanChoice(
          products: const [FakeStoreBilling.monthly],
          featured: SubscriptionPlan.yearly,
        );
        expect(choice.initialPlan, SubscriptionPlan.monthly);
        expect(choice.yearlySavingPercent, isNull);
      },
    );
  });
}
