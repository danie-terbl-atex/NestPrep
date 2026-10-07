import 'dart:io';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/household/data/household_failure_mapper.dart';
import 'package:nestprep/shared/copy/app_copy.dart';
import 'package:nestprep/shared/failure/app_failure.dart';

/// The contract `BE-04` rests on, checked across the two languages that share
/// it.
///
/// A callable refuses by putting its own `reason` in the error's details, and
/// the client turns that string into a `HouseholdProblem` and then into a
/// sentence. Nothing has ever checked that the two sides agree. If the server
/// gains a reason the client has never heard of, nobody sees an error — they
/// see "Something went wrong", which is the worst possible outcome: a refusal
/// the app knows exactly how to explain, explained as a shrug.
///
/// So this reads the server's own source rather than a copy of it. It fails
/// when the two drift, which is the only moment it could ever be useful.
void main() {
  /// Where the server keeps each set of reasons.
  final errorsFile = File('../functions/src/household/errors.ts');
  final parseInputFile = File('../functions/src/household/parse_input.ts');

  /// The keys of `HOUSEHOLD_REFUSALS`, read out of the TypeScript.
  Set<String> refusalsDeclaredByTheServer() {
    final source = errorsFile.readAsStringSync();
    final block = source.substring(
      source.indexOf('HOUSEHOLD_REFUSALS = {'),
      source.indexOf('} as const satisfies'),
    );
    return RegExp(
      r'^\s{2}(\w+):',
      multiLine: true,
    ).allMatches(block).map((match) => match.group(1)!).toSet();
  }

  /// The reasons the input edge throws, which are not in that map.
  Set<String> reasonsFromTheInputEdge() {
    final source = parseInputFile.readAsStringSync();
    return RegExp(
      r"reason:\s*'(\w+)'",
    ).allMatches(source).map((match) => match.group(1)!).toSet();
  }

  test('the server source is where this test thinks it is', () {
    expect(
      errorsFile.existsSync(),
      isTrue,
      reason:
          'if errors.ts moved, this contract lost its home — point the '
          'test at the new one rather than deleting it',
    );
    expect(parseInputFile.existsSync(), isTrue);
    expect(
      refusalsDeclaredByTheServer(),
      isNotEmpty,
      reason: 'parsing found nothing, which means the shape changed',
    );
  });

  test('every reason the server can send, the client can name', () {
    final clientKnows = {
      for (final problem in HouseholdProblem.values) problem.name,
    };
    final serverSends = {
      ...refusalsDeclaredByTheServer(),
      ...reasonsFromTheInputEdge(),
    };

    expect(
      serverSends.difference(clientKnows),
      isEmpty,
      reason: 'a reason the client cannot name becomes "Something went wrong"',
    );
  });

  test('and every reason the client knows, the server can send', () {
    // `unrecognised` is the client's own: it is what a reason from a newer
    // Function becomes. Everything else should be something the server says.
    const clientOnly = {HouseholdProblem.unrecognised};
    final serverSends = {
      ...refusalsDeclaredByTheServer(),
      ...reasonsFromTheInputEdge(),
    };

    final orphans = [
      for (final problem in HouseholdProblem.values)
        if (!clientOnly.contains(problem) &&
            !serverSends.contains(problem.name))
          problem.name,
    ];

    expect(
      orphans,
      isEmpty,
      reason:
          'copy for a refusal that can no longer happen is copy nobody '
          'will ever read, and a reader will trust it anyway',
    );
  });

  test('every one of them has words', () {
    for (final problem in HouseholdProblem.values) {
      expect(
        AppCopy.householdProblem(problem).trim(),
        isNotEmpty,
        reason: '${problem.name} can reach a screen',
      );
    }
  });

  group('the mapper at the data edge', () {
    FirebaseFunctionsException refusal({
      required String code,
      Object? details,
    }) => FirebaseFunctionsException(
      code: code,
      message: 'for the log, not for a person',
      details: details,
    );

    // `AppFailure` has no value equality — nothing in the app compares two
    // failures — so these check the type and the problem, not the instance.
    HouseholdProblem problemOf(AppFailure failure) =>
        (failure as HouseholdFailure).problem;

    test('a reason both sides know becomes that problem', () {
      final failure = failureFromCallable(
        refusal(code: 'not-found', details: {'reason': 'inviteExpired'}),
      );
      expect(failure, isA<HouseholdFailure>());
      expect(problemOf(failure), HouseholdProblem.inviteExpired);
    });

    test('a reason from a newer Function becomes the honest shrug', () {
      final failure = failureFromCallable(
        refusal(
          code: 'failed-precondition',
          details: {'reason': 'inviteRevoked'},
        ),
      );
      expect(failure, isA<HouseholdFailure>());
      expect(
        problemOf(failure),
        HouseholdProblem.unrecognised,
        reason: 'an app older than its backend must still say something',
      );
    });

    group('and with no reason at all, falls back to the gRPC code', () {
      for (final (code, expected) in [
        ('unauthenticated', HouseholdFailure),
        ('permission-denied', PermissionDeniedFailure),
        ('unavailable', UnavailableFailure),
        ('deadline-exceeded', UnavailableFailure),
        ('not-found', NotFoundFailure),
      ]) {
        test(code, () {
          expect(
            failureFromCallable(refusal(code: code)).runtimeType,
            expected,
          );
        });
      }

      test('an unauthenticated call names the reason, not just the type', () {
        expect(
          problemOf(failureFromCallable(refusal(code: 'unauthenticated'))),
          HouseholdProblem.notSignedIn,
        );
      });

      test('and a code nobody planned for is unknown, not a crash', () {
        expect(
          failureFromCallable(refusal(code: 'resource-exhausted')),
          isA<UnknownFailure>(),
        );
      });
    });

    test('details that are not a map are ignored rather than trusted', () {
      expect(
        failureFromCallable(
          refusal(code: 'not-found', details: 'a string'),
        ).runtimeType,
        NotFoundFailure,
      );
    });
  });
}
