import 'dart:io';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/family_profiles/data/callable_child_profile_directory.dart';
import 'package:nestprep/features/subscriptions/data/callable_subscription_directory.dart';
import 'package:nestprep/features/subscriptions/data/firestore_entitlement_repository.dart';
import 'package:nestprep/features/subscriptions/data/subscription_failure_mapper.dart';
import 'package:nestprep/features/subscriptions/model/billing_store.dart';
import 'package:nestprep/features/subscriptions/model/entitlement.dart';
import 'package:nestprep/features/subscriptions/model/entitlement_status.dart';
import 'package:nestprep/features/subscriptions/model/premium_feature.dart';
import 'package:nestprep/features/subscriptions/model/subscription_plan.dart';
import 'package:nestprep/shared/copy/app_copy.dart';
import 'package:nestprep/shared/failure/app_failure.dart';

/// Subscriptions' lists written down in both languages (subscriptions
/// ADR-0001): the refusals, the triggers analytics counts, the stores, the
/// plans and statuses the entitlement carries, its field names, and the
/// callables' names. Each test reads the server's own source, so the two
/// cannot drift without something going red — the lesson on contracts
/// between two languages.
void main() {
  String source(String path) =>
      File('../functions/src/$path').readAsStringSync();

  Set<String> stringsOf(String text, String constant) {
    final start = text.indexOf('$constant = [');
    expect(start, isNonNegative, reason: constant);
    final block = text.substring(start, text.indexOf('] as const', start));
    return RegExp("'(\\w+)'").allMatches(block).map((m) => m.group(1)!).toSet();
  }

  Set<String> refusals() {
    final text = source('subscriptions/errors.ts');
    final start = text.indexOf('SUBSCRIPTION_REFUSALS = {');
    final block = text.substring(start, text.indexOf('} as const', start));
    return RegExp(
      r'^\s{2}(\w+):',
      multiLine: true,
    ).allMatches(block).map((m) => m.group(1)!).toSet();
  }

  AppFailure mapped(String reason, {Object? feature}) =>
      failureFromSubscriptionCallable(
        FirebaseFunctionsException(
          code: 'failed-precondition',
          message: 'for the log, not for a person',
          details: {'reason': reason, 'feature': ?feature},
        ),
      );

  test('the paywall’s features are the triggers analytics counts', () {
    expect(
      PremiumFeature.values.map((f) => f.name).toSet(),
      stringsOf(
        source('product_analytics/conversion_ledger.ts'),
        'CONVERSION_TRIGGERS',
      ),
    );
  });

  test('the stores, plans and statuses are the server’s', () {
    final state = source('subscriptions/purchase_state.ts');
    expect(
      BillingStore.values.map((s) => s.name).toSet(),
      stringsOf(state, 'BILLING_STORES'),
    );
    expect(
      SubscriptionPlan.values.map((p) => p.name).toSet(),
      stringsOf(state, 'PLANS'),
    );
    expect(EntitlementStatus.values.map((s) => s.name).toSet(), {
      ...stringsOf(state, 'PURCHASE_STATUSES'),
      'none',
    });
  });

  test('every field the app reads off the entitlement, the server writes', () {
    final written = source('subscriptions/subscription_documents.ts');
    for (final field in const Entitlement().toJson().keys) {
      expect(written, contains('    $field:'), reason: field);
    }
    expect(
      source('subscriptions/subscription_documents.ts'),
      contains(
        "ENTITLEMENT = '${FirestoreEntitlementRepository.entitlementPath}'",
      ),
    );
    expect(
      written,
      contains(
        "CURRENT = '${FirestoreEntitlementRepository.currentEntitlement}'",
      ),
    );
  });

  test('the callables the app calls are the ones the server exports', () {
    final index = source('index.ts');
    for (final name in [
      CallableSubscriptionDirectory.offerCallable,
      CallableSubscriptionDirectory.verifyCallable,
      CallableChildProfileDirectory.callableName,
    ]) {
      expect(index, contains('export { $name }'), reason: name);
    }
  });

  test('every refusal the server can send, the client can name', () {
    final known = {
      for (final problem in SubscriptionProblem.values) problem.name,
      for (final problem in HouseholdProblem.values) problem.name,
      'premiumRequired',
    };
    expect(refusals().difference(known), isEmpty);
  });

  test('and each becomes a sentence, never the reason itself', () {
    for (final reason in refusals()) {
      final copy = AppCopy.failure(mapped(reason));
      expect(copy.trim(), isNotEmpty, reason: reason);
      expect(copy, isNot(contains(reason)), reason: reason);
    }
  });

  test('the free tier’s refusal carries the feature it was reached on', () {
    expect(
      mapped('premiumRequired', feature: 'additionalChild'),
      isA<PremiumRequiredFailure>().having(
        (failure) => failure.feature,
        'feature',
        PremiumFeature.additionalChild,
      ),
    );
    // A feature this build does not know still opens the paywall.
    expect(
      mapped('premiumRequired', feature: 'teleportation'),
      isA<PremiumRequiredFailure>().having(
        (failure) => failure.feature,
        'feature',
        PremiumFeature.direct,
      ),
    );
  });

  test('a refusal only the phone raises is not one the server lost', () {
    const phoneOnly = {
      SubscriptionProblem.storeNotAvailable,
      SubscriptionProblem.productsNotFound,
      SubscriptionProblem.purchaseFailed,
      SubscriptionProblem.nothingToRestore,
    };
    final fromServer = SubscriptionProblem.values
        .where((problem) => !phoneOnly.contains(problem))
        .map((problem) => problem.name)
        .toSet();
    expect(fromServer.difference(refusals()), isEmpty);
  });
}
