import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/two_homes/data/callable_json.dart';
import 'package:nestprep/features/two_homes/data/two_homes_failure_mapper.dart';
import 'package:nestprep/shared/copy/app_copy.dart';
import 'package:nestprep/shared/failure/app_failure.dart';

/// A co-parenting refusal reaches the screen as words, chosen by the reason
/// the Function put in its details (`BE-04`, household ADR-0004).
void main() {
  FirebaseFunctionsException refusal(String code, [String? reason]) =>
      FirebaseFunctionsException(
        code: code,
        message: 'refused',
        details: reason == null ? null : {'reason': reason},
      );

  test('each of the feature’s own reasons becomes its own problem', () {
    for (final problem in CoParentProblem.values) {
      final failure = failureFromTwoHomesCallable(
        refusal('failed-precondition', problem.name),
      );
      expect(failure, isA<CoParentFailure>());
      expect((failure as CoParentFailure).problem, problem);
      expect(AppCopy.failure(failure), isNotEmpty);
    }
  });

  test('membership keeps the household’s words', () {
    final failure = failureFromTwoHomesCallable(
      refusal('permission-denied', 'notAnAdmin'),
    );
    expect(failure, isA<HouseholdFailure>());
    expect((failure as HouseholdFailure).problem, HouseholdProblem.notAnAdmin);
  });

  test('with no reason, the code decides', () {
    expect(
      failureFromTwoHomesCallable(refusal('unauthenticated')),
      isA<HouseholdFailure>(),
    );
    expect(
      failureFromTwoHomesCallable(refusal('permission-denied')),
      isA<PermissionDeniedFailure>(),
    );
    expect(
      failureFromTwoHomesCallable(refusal('unavailable')),
      isA<UnavailableFailure>(),
    );
    expect(
      failureFromTwoHomesCallable(refusal('not-found')),
      isA<NotFoundFailure>(),
    );
    expect(
      failureFromTwoHomesCallable(refusal('internal', 'somethingNew')),
      isA<UnknownFailure>(),
    );
  });

  test('no refusal copy blames anybody', () {
    for (final problem in CoParentProblem.values) {
      final words = TwoHomesCopy.problem(problem).toLowerCase();
      for (final blame in [
        'refused',
        'rejected',
        'denied',
        'fault',
        'your ex',
      ]) {
        expect(words, isNot(contains(blame)), reason: problem.name);
      }
    }
  });

  group('a callable’s answer', () {
    test('is rebuilt as string-keyed maps all the way down', () {
      final answer = stringKeyed(<Object?, Object?>{
        'home': <Object?, Object?>{'name': 'Mum’s home'},
        'blocks': [
          <Object?, Object?>{'side': 'a'},
        ],
        7: 'dropped',
      });
      expect(answer, {
        'home': {'name': 'Mum’s home'},
        'blocks': [
          {'side': 'a'},
        ],
      });
      expect(stringKeyed('not a map'), isNull);
    });

    test('that does not parse is an UnknownFailure, not a crash', () {
      expect(
        () => parseOrFail<int>('x', () => throw const FormatException('no')),
        throwsA(isA<UnknownFailure>()),
      );
      expect(
        () => parseOrFail<int>('x', () => (null as Object?)! as int),
        throwsA(isA<UnknownFailure>()),
      );
      expect(parseOrFail('x', () => 3), 3);
    });
  });
}
