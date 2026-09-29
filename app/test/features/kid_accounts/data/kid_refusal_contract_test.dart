import 'dart:io';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/kid_accounts/data/kid_failure_mapper.dart';
import 'package:nestprep/shared/failure/app_failure.dart';

/// The kid sign-in refusals, checked across the two languages that share them
/// (accounts ADR-0003, `BE-04`) — the same contract the household refusals
/// have, for the same reason: a reason the client cannot name reaches a child
/// as "something went wrong" when the app had the right words all along.
void main() {
  final errorsFile = File('../functions/src/accounts/kid_errors.ts');

  Set<String> refusalsDeclaredByTheServer() {
    final source = errorsFile.readAsStringSync();
    final block = source.substring(
      source.indexOf('KID_REFUSALS = {'),
      source.indexOf('} as const satisfies'),
    );
    return RegExp(
      r'^\s{2}(\w+):',
      multiLine: true,
    ).allMatches(block).map((match) => match.group(1)!).toSet();
  }

  /// The client's own: what a device the rules have started refusing becomes.
  const clientOnly = {KidSignInProblem.deviceDisconnected};

  test('the server source is where this test thinks it is', () {
    expect(errorsFile.existsSync(), isTrue);
    expect(refusalsDeclaredByTheServer(), isNotEmpty);
  });

  test('every reason the server can send, the client can name', () {
    final clientKnows = {
      for (final problem in KidSignInProblem.values) problem.name,
    };
    expect(refusalsDeclaredByTheServer().difference(clientKnows), isEmpty);
  });

  test('and every reason the client knows, the server can send', () {
    final serverSends = refusalsDeclaredByTheServer();
    expect([
      for (final problem in KidSignInProblem.values)
        if (!clientOnly.contains(problem) &&
            !serverSends.contains(problem.name))
          problem.name,
    ], isEmpty);
  });

  group('the mapper at the data edge', () {
    FirebaseFunctionsException refusal(String code, Object? reason) =>
        FirebaseFunctionsException(
          code: code,
          message: 'for the log',
          details: reason == null ? null : {'reason': reason},
        );

    test('a kid reason becomes that kid problem', () {
      final failure = failureFromKidCallable(
        refusal('deadline-exceeded', 'codeExpired'),
      );
      expect(
        failure,
        isA<KidSignInFailure>().having(
          (value) => value.problem,
          'problem',
          KidSignInProblem.codeExpired,
        ),
      );
    });

    test('a household reason keeps the household words', () {
      expect(
        failureFromKidCallable(refusal('permission-denied', 'notAnAdmin')),
        isA<HouseholdFailure>().having(
          (value) => value.problem,
          'problem',
          HouseholdProblem.notAnAdmin,
        ),
      );
      expect(
        failureFromKidCallable(refusal('permission-denied', 'kidAccount')),
        isA<HouseholdFailure>().having(
          (value) => value.problem,
          'problem',
          HouseholdProblem.kidAccount,
        ),
      );
    });

    test('no reason at all falls back to the gRPC code, as elsewhere', () {
      expect(
        failureFromKidCallable(refusal('unavailable', null)),
        isA<UnavailableFailure>(),
      );
    });
  });
}
