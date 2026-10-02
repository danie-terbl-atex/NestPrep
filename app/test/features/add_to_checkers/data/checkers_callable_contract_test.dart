import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/add_to_checkers/data/checkers_failure_mapper.dart';
import 'package:nestprep/features/add_to_checkers/data/checkers_push_result_parser.dart';
import 'package:nestprep/features/add_to_checkers/model/checkers_push_result.dart';
import 'package:nestprep/shared/copy/app_copy.dart';
import 'package:nestprep/shared/failure/app_failure.dart';

AppFailure refusal(String code, String? reason) => failureFromCheckersCallable(
  FirebaseFunctionsException(
    code: code,
    message: 'for the log, not for a person',
    details: reason == null ? null : {'reason': reason},
  ),
);

/// The seam with the Checkers callables: every refusal reason the Functions
/// send becomes its own sentence, and the push answer reads into a result.
void main() {
  const reasons = {
    'bad-mobile': CheckersProblem.badMobile,
    'otp-rate-limited': CheckersProblem.otpRateLimited,
    'checkers-down': CheckersProblem.checkersDown,
    'no-pending-otp': CheckersProblem.noPendingOtp,
    'wrong-code': CheckersProblem.wrongCode,
    'checkers-link-expired': CheckersProblem.linkExpired,
    'no-checkers-store': CheckersProblem.noStoreForAccount,
    'checkers-switched-off': CheckersProblem.featureOff,
  };

  for (final MapEntry(key: reason, value: problem) in reasons.entries) {
    test('"$reason" is its own sentence, never the server’s words', () {
      final failure = refusal('failed-precondition', reason);
      expect(failure, isA<CheckersFailure>());
      expect((failure as CheckersFailure).problem, problem);
      expect(AppCopy.failure(failure), isNot(contains('log')));
    });
  }

  test('the household reasons read as the household’s failures', () {
    expect(
      refusal('permission-denied', 'not-a-member'),
      isA<HouseholdFailure>().having(
        (failure) => failure.problem,
        'problem',
        HouseholdProblem.notAMember,
      ),
    );
    expect(
      (refusal('permission-denied', 'kidAccount') as HouseholdFailure).problem,
      HouseholdProblem.kidAccount,
    );
    expect(
      (refusal('invalid-argument', 'badRequest') as HouseholdFailure).problem,
      HouseholdProblem.badRequest,
    );
  });

  test('with no reason, the code decides', () {
    expect(refusal('unavailable', null), isA<UnavailableFailure>());
    expect(
      (refusal('resource-exhausted', null) as CheckersFailure).problem,
      CheckersProblem.otpRateLimited,
    );
    expect(refusal('internal', null), isA<UnknownFailure>());
  });

  test('a push answer reads into what was added, skipped and the cart', () {
    final result = CheckersPushResultParser.parse({
      'added': [
        {
          'itemId': 'i1',
          'productId': '5d3af63bf434cf8420737dd6',
          'name': 'Clover Fresh Full Cream Milk 2L',
          'priceCents': 3799,
        },
      ],
      'skipped': [
        {'itemId': 'i2', 'reason': 'weighed-item'},
        {'itemId': 'i3', 'reason': 'something-new'},
      ],
      'cartItemCount': 4,
      'cartTotalCents': 12396,
    });
    expect(result, isNotNull);
    expect(result!.added.single.price.cents, 3799);
    expect(
      [for (final line in result.skipped) line.reason],
      [CheckersSkipReason.weighedItem, CheckersSkipReason.unrecognised],
    );
    expect(result.cartItemCount, 4);
    expect(result.cartTotal.display, 'R123.96');
  });

  test('a push answer of the wrong shape is not a result', () {
    expect(CheckersPushResultParser.parse({'added': 'lots'}), isNull);
  });
}
