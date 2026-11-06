import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/add_to_woolworths/data/woolworths_failure_mapper.dart';
import 'package:nestprep/features/add_to_woolworths/model/woolworths_sign_in.dart';
import 'package:nestprep/shared/copy/app_copy.dart';
import 'package:nestprep/shared/failure/app_failure.dart';

AppFailure refusal(String code, String? reason) =>
    failureFromWoolworthsCallable(
      FirebaseFunctionsException(
        code: code,
        message: 'for the log, not for a person',
        details: reason == null ? null : {'reason': reason},
      ),
    );

/// The seam with the Woolworths callables (add-to-woolworths ADR-0001):
/// every refusal reason the Functions send becomes its own sentence, and the
/// sign-in the server names can only be an AWS Cognito endpoint.
void main() {
  const reasons = {
    'woolworths-off': WoolworthsProblem.featureOff,
    'woolworths-switched-off': WoolworthsProblem.featureOff,
    'woolworths-not-linked': WoolworthsProblem.notLinked,
    'woolworths-link-expired': WoolworthsProblem.linkExpired,
    'woolworths-link-rejected': WoolworthsProblem.linkRejected,
    'woolworths-unavailable': WoolworthsProblem.woolworthsDown,
    'woolworths-rejected': WoolworthsProblem.cartRefused,
    'woolworths-no-delivery-address': WoolworthsProblem.noDeliveryAddress,
  };

  for (final MapEntry(key: reason, value: problem) in reasons.entries) {
    test('"$reason" is its own sentence, never the server’s words', () {
      final failure = refusal('failed-precondition', reason);
      expect(failure, isA<WoolworthsFailure>());
      expect((failure as WoolworthsFailure).problem, problem);
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

  test('the sign-in is only ever a Cognito app client in an AWS region', () {
    final cognito = WoolworthsCognito.tryFrom(
      clientId: 'abcdefghij0123456789klmnop',
      region: 'eu-west-1',
    );
    expect(
      cognito?.endpoint,
      Uri.https('cognito-idp.eu-west-1.amazonaws.com', '/'),
    );
    for (final (clientId, region) in [
      ('', 'eu-west-1'),
      ('abc/def', 'eu-west-1'),
      ('abc', 'eu-west-1.evil.com/'),
      ('abc', 'evil.com#'),
      ('abc', ''),
    ]) {
      expect(
        WoolworthsCognito.tryFrom(clientId: clientId, region: region),
        isNull,
        reason: '$clientId $region',
      );
    }
  });
}
