import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/home_care/data/home_care_failure_mapper.dart';
import 'package:nestprep/shared/failure/app_failure.dart';

/// A home-care callable's refusal, turned into words the app has (home-care
/// ADR-0006, `BE-04`): by its reason first, by its code when it has none, and
/// never an SDK message on a helper's screen.
void main() {
  FirebaseFunctionsException refusal(String code, [String? reason]) =>
      FirebaseFunctionsException(
        code: code,
        message: 'for a log, never a person',
        details: reason == null ? null : {'reason': reason},
      );

  test('a home-care reason is home care’s problem', () {
    expect(
      failureFromHomeCareCallable(
        refusal('resource-exhausted', 'translationLimitReached'),
      ),
      isA<HomeCareFailure>().having(
        (failure) => failure.problem,
        'problem',
        HomeCareProblem.translationLimitReached,
      ),
    );
  });

  test('a membership reason keeps the household’s words', () {
    expect(
      failureFromHomeCareCallable(refusal('permission-denied', 'notAMember')),
      isA<HouseholdFailure>(),
    );
  });

  test('no reason falls back on the code', () {
    expect(
      failureFromHomeCareCallable(refusal('unauthenticated')),
      isA<HouseholdFailure>().having(
        (failure) => failure.problem,
        'problem',
        HouseholdProblem.notSignedIn,
      ),
    );
    expect(
      failureFromHomeCareCallable(refusal('permission-denied')),
      isA<PermissionDeniedFailure>(),
    );
    expect(
      failureFromHomeCareCallable(refusal('unavailable')),
      isA<UnavailableFailure>(),
    );
    expect(
      failureFromHomeCareCallable(refusal('internal', 'somethingNew')),
      isA<UnknownFailure>(),
    );
  });
}
