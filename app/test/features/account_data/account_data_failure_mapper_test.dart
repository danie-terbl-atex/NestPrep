import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/account_data/data/account_data_failure_mapper.dart';
import 'package:nestprep/shared/failure/app_failure.dart';

/// The account-data callables' refusals become the right failure (accounts
/// ADR-0006, `BE-04`): their own reasons by name, and the household's words —
/// "sign in first", "a kid sign-in cannot do that" — through the household's
/// mapper, so there is one fallback, not two.
void main() {
  FirebaseFunctionsException refusal(String code, String? reason) =>
      FirebaseFunctionsException(
        code: code,
        message: 'for a log',
        details: reason == null ? null : {'reason': reason},
      );

  test('reads every reason the Functions send, by name', () {
    for (final (reason, problem) in [
      ('deletionPlanChanged', AccountDataProblem.deletionPlanChanged),
      ('deletionNotConfirmed', AccountDataProblem.deletionNotConfirmed),
      ('tooManyRequests', AccountDataProblem.tooManyRequests),
    ]) {
      final failure = failureFromAccountDataCallable(
        refusal('failed-precondition', reason),
      );
      expect(
        failure,
        isA<AccountDataFailure>().having((f) => f.problem, reason, problem),
      );
    }
  });

  test('a kid device and a signed-out caller are the household’s words', () {
    expect(
      failureFromAccountDataCallable(
        refusal('permission-denied', 'kidAccount'),
      ),
      isA<HouseholdFailure>().having(
        (f) => f.problem,
        'problem',
        HouseholdProblem.kidAccount,
      ),
    );
    expect(
      failureFromAccountDataCallable(refusal('unauthenticated', 'notSignedIn')),
      isA<HouseholdFailure>().having(
        (f) => f.problem,
        'problem',
        HouseholdProblem.notSignedIn,
      ),
    );
  });

  test('no reason at all falls back on the code', () {
    expect(
      failureFromAccountDataCallable(refusal('unavailable', null)),
      isA<UnavailableFailure>(),
    );
  });
}
