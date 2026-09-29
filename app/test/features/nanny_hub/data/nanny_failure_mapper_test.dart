import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/nanny_hub/data/nanny_failure_mapper.dart';
import 'package:nestprep/shared/copy/app_copy.dart';
import 'package:nestprep/shared/failure/app_failure.dart';

/// `endNannyShift`'s refusals become words by their `reason`, never by the
/// gRPC code alone — two of them are `permission-denied` (`BE-04`).
void main() {
  FirebaseFunctionsException refusal(String code, [String? reason]) =>
      FirebaseFunctionsException(
        code: code,
        message: 'for the log',
        details: reason == null ? null : {'reason': reason},
      );

  test('tells the two permission refusals apart by their reason', () {
    expect(
      failureFromNannyCallable(refusal('permission-denied', 'notYourShift')),
      isA<NannyHubFailure>().having(
        (failure) => failure.problem,
        'problem',
        NannyHubProblem.notYourShift,
      ),
    );
    expect(
      failureFromNannyCallable(refusal('permission-denied', 'hubNotShared')),
      isA<NannyHubFailure>().having(
        (failure) => failure.problem,
        'problem',
        NannyHubProblem.hubNotShared,
      ),
    );
  });

  test('keeps the household’s words for a household refusal', () {
    expect(
      failureFromNannyCallable(refusal('permission-denied', 'notAMember')),
      isA<HouseholdFailure>(),
    );
    expect(
      failureFromNannyCallable(refusal('invalid-argument', 'badRequest')),
      isA<HouseholdFailure>(),
    );
  });

  test('falls back on the code for a reason this build does not know', () {
    expect(
      failureFromNannyCallable(refusal('unavailable', 'somethingNew')),
      isA<UnavailableFailure>(),
    );
    expect(
      failureFromNannyCallable(refusal('internal')),
      isA<UnknownFailure>(),
    );
  });

  test('every problem has words, and none of them is a code', () {
    for (final problem in NannyHubProblem.values) {
      final words = AppCopy.failure(NannyHubFailure(problem));
      expect(words, isNotEmpty);
      expect(words, isNot(contains(problem.name)));
    }
  });
}
