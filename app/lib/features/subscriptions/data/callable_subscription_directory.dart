import 'package:cloud_functions/cloud_functions.dart';

import '../model/billing_store.dart';
import '../model/premium_feature.dart';
import '../model/subscription_offer.dart';
import '../model/subscription_plan.dart';
import 'subscription_directory.dart';
import 'subscription_failure_mapper.dart';

/// The subscriptions callables over the Functions SDK. Each answer is parsed
/// rather than cast (`ENG-09`): an answer of the wrong shape is a Function
/// newer or older than this build, and reads as "not on sale" rather than
/// crashing.
final class CallableSubscriptionDirectory implements SubscriptionDirectory {
  const CallableSubscriptionDirectory(this._functions);

  final FirebaseFunctions _functions;

  static const offerCallable = 'getSubscriptionOffer';
  static const verifyCallable = 'verifyPurchase';

  @override
  Future<SubscriptionOffer> offer(String householdId) async {
    final result = await _call(offerCallable, {'householdId': householdId});
    final productIds = <SubscriptionPlan, String>{};
    if (result['products'] case final List<Object?> products) {
      for (final product in products) {
        if (product case {
          'productId': final String id,
          'plan': final Object? name,
        }) {
          final plan = _planNamed(name);
          if (plan != null) productIds[plan] = id;
        }
      }
    }
    final isAvailable = result['isAvailable'] == true && productIds.isNotEmpty;
    final cohort = result['cohort'];
    return SubscriptionOffer(
      isAvailable: isAvailable,
      canBuy: result['canBuy'] == true,
      cohort: cohort is String ? cohort : 'a',
      featuredPlan:
          _planNamed(result['featuredPlan']) ?? SubscriptionPlan.yearly,
      productIds: isAvailable ? productIds : const {},
    );
  }

  @override
  Future<bool> verify({
    required String householdId,
    required BillingStore store,
    required String verificationData,
    required PremiumFeature? trigger,
  }) async {
    final result = await _call(verifyCallable, {
      'householdId': householdId,
      'store': store.name,
      'verificationData': verificationData,
      'trigger': trigger?.name,
    });
    return result['isPremium'] == true;
  }

  static SubscriptionPlan? _planNamed(Object? name) =>
      SubscriptionPlan.values.where((plan) => plan.name == name).firstOrNull;

  Future<Map<Object?, Object?>> _call(
    String name,
    Map<String, Object?> payload,
  ) async {
    try {
      final result = await _functions
          .httpsCallable(name)
          .call<Object?>(payload);
      final data = result.data;
      return data is Map ? data : const {};
    } on FirebaseFunctionsException catch (error) {
      throw failureFromSubscriptionCallable(error);
    }
  }
}
