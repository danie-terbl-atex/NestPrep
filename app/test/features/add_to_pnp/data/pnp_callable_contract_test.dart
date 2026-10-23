import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/add_to_checkers/data/cart_push_result_parser.dart';
import 'package:nestprep/features/add_to_checkers/model/cart_push_result.dart';
import 'package:nestprep/features/add_to_pnp/data/pnp_failure_mapper.dart';
import 'package:nestprep/shared/copy/app_copy.dart';
import 'package:nestprep/shared/failure/app_failure.dart';

AppFailure refusal(String code, String? reason) => failureFromPnpCallable(
  FirebaseFunctionsException(
    code: code,
    message: 'for the log, not for a person',
    details: reason == null ? null : {'reason': reason},
  ),
);

/// The seam with the Pick n Pay callables (add-to-pnp ADR-0003): every
/// refusal reason the Functions send becomes its own sentence, and the push
/// answer — Checkers' shape, with `cart-full` — reads into a result.
void main() {
  const reasons = {
    'pnp-switched-off': PnpProblem.featureOff,
    'pnp-no-pending-link': PnpProblem.noPendingLink,
    'pnp-link-refused': PnpProblem.linkRefused,
    'pnp-link-expired': PnpProblem.linkExpired,
    'pnp-down': PnpProblem.pnpDown,
    'pnp-no-delivery-address': PnpProblem.noDeliveryAddress,
  };

  for (final MapEntry(key: reason, value: problem) in reasons.entries) {
    test('"$reason" is its own sentence, never the server’s words', () {
      final failure = refusal('failed-precondition', reason);
      expect(failure, isA<PnpFailure>());
      expect((failure as PnpFailure).problem, problem);
      expect(AppCopy.failure(failure), isNot(contains('log')));
    });
  }

  test('not a member reads as the household’s refusal', () {
    expect(
      refusal('permission-denied', 'not-a-member'),
      isA<HouseholdFailure>().having(
        (failure) => failure.problem,
        'problem',
        HouseholdProblem.notAMember,
      ),
    );
  });

  test('with no reason, the code decides', () {
    expect(refusal('unavailable', null), isA<UnavailableFailure>());
    expect(refusal('internal', null), isA<UnknownFailure>());
  });

  test('a push answer with a full cart reads, reason and all', () {
    final result = CartPushResultParser.parse(const {
      'added': [
        {
          'itemId': 'i1',
          'productId': '000000000000539078_EA',
          'name': 'Mini Cheddars',
          'priceCents': 4899,
        },
      ],
      'skipped': [
        {'itemId': 'i2', 'reason': 'cart-full'},
      ],
      'cartItemCount': 45,
      'cartTotalCents': 120000,
    })!;
    expect(result.added.single.price.cents, 4899);
    expect(result.skipped.single.reason, CartSkipReason.cartFull);
    expect(result.cartItemCount, 45);
  });

  test('every skip reason the PnP push sends is one this build knows', () {
    // The strings `functions/src/cart_push/push_outcome.ts` sends.
    const sent = {
      'no-match': CartSkipReason.noMatch,
      'out-of-stock': CartSkipReason.outOfStock,
      'not-found': CartSkipReason.notFound,
      'weighed-item': CartSkipReason.weighedItem,
      'cart-full': CartSkipReason.cartFull,
      'low-stock': CartSkipReason.lowStock,
      'max-quantity': CartSkipReason.maxQuantity,
      'shop-refused': CartSkipReason.shopRefused,
    };
    for (final MapEntry(key: code, value: reason) in sent.entries) {
      expect(CartSkipReason.fromCode(code), reason, reason: code);
    }
  });
}
