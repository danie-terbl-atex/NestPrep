import 'dart:io';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/chore_points/data/points_failure_mapper.dart';
import 'package:nestprep/shared/failure/app_failure.dart';

/// The chore-points refusals, checked across the two languages that share
/// them (todos ADR-0003, `BE-04`): a reason the client cannot name reaches a
/// parent as "something went wrong" when the app had the right words.
void main() {
  final errorsFile = File('../functions/src/chore_points/errors.ts');

  Set<String> refusalsDeclaredByTheServer() {
    final source = errorsFile.readAsStringSync();
    final block = source.substring(
      source.indexOf('CHORE_POINT_REFUSALS = {'),
      source.indexOf('} as const satisfies'),
    );
    return RegExp(
      r'^\s{2}(\w+):',
      multiLine: true,
    ).allMatches(block).map((match) => match.group(1)!).toSet();
  }

  /// Said in the household's words, which the client already has.
  const householdWords = {'notAMember'};

  test('the server source is where this test thinks it is', () {
    expect(errorsFile.existsSync(), isTrue);
    expect(refusalsDeclaredByTheServer(), contains('notFamily'));
  });

  test('every reason the server can send, the client can name', () {
    final clientKnows = {
      for (final problem in PointsProblem.values) problem.name,
      ...householdWords,
      ...{for (final problem in HouseholdProblem.values) problem.name},
    };
    expect(refusalsDeclaredByTheServer().difference(clientKnows), isEmpty);
  });

  test('and every reason the client knows, the server can send', () {
    final serverSends = refusalsDeclaredByTheServer();
    expect([
      for (final problem in PointsProblem.values)
        if (!serverSends.contains(problem.name)) problem.name,
    ], isEmpty);
  });

  group('the mapper at the data edge', () {
    FirebaseFunctionsException refusal(String code, Object? reason) =>
        FirebaseFunctionsException(
          code: code,
          message: 'for the log',
          details: reason == null ? null : {'reason': reason},
        );

    test('a points reason becomes that points problem', () {
      expect(
        failureFromPointsCallable(
          refusal('failed-precondition', 'alreadySettled'),
        ),
        isA<PointsFailure>().having(
          (f) => f.problem,
          'problem',
          PointsProblem.alreadySettled,
        ),
      );
    });

    test('a household reason stays the household’s', () {
      expect(
        failureFromPointsCallable(refusal('permission-denied', 'kidAccount')),
        isA<HouseholdFailure>().having(
          (f) => f.problem,
          'problem',
          HouseholdProblem.kidAccount,
        ),
      );
    });

    test('no reason at all falls back on the code', () {
      expect(
        failureFromPointsCallable(refusal('unavailable', null)),
        isA<UnavailableFailure>(),
      );
    });
  });
}
