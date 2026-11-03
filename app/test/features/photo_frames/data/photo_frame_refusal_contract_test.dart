import 'dart:io';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/photo_frames/data/photo_frame_failure_mapper.dart';
import 'package:nestprep/shared/failure/app_failure.dart';

void main() {
  final errorsFile = File('../functions/src/frames/frame_errors.ts');

  Set<String> refusalsDeclaredByTheServer() {
    final source = errorsFile.readAsStringSync();
    final start = source.indexOf('FRAME_REFUSALS = {');
    final block = source.substring(start, source.indexOf('} as const', start));
    return RegExp(
      r'^\s{2}(\w+):',
      multiLine: true,
    ).allMatches(block).map((match) => match.group(1)!).toSet();
  }

  test('the server source is where this test thinks it is', () {
    expect(errorsFile.existsSync(), isTrue);
    expect(refusalsDeclaredByTheServer(), isNotEmpty);
  });

  test('every reason the server can send, the client can name', () {
    final clientKnows = {
      for (final problem in PhotoFrameProblem.values) problem.name,
      for (final problem in HouseholdProblem.values) problem.name,
    };
    expect(refusalsDeclaredByTheServer().difference(clientKnows), isEmpty);
  });

  test('and every reason the client knows, the server can send', () {
    final serverSends = refusalsDeclaredByTheServer();
    expect([
      for (final problem in PhotoFrameProblem.values)
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

    for (final problem in PhotoFrameProblem.values) {
      test('${problem.name} becomes that frame problem', () {
        expect(
          failureFromFrameCallable(
            refusal('failed-precondition', problem.name),
          ),
          isA<PhotoFrameFailure>().having(
            (value) => value.problem,
            'problem',
            problem,
          ),
        );
      });
    }

    test('a household reason keeps the household words', () {
      expect(
        failureFromFrameCallable(refusal('permission-denied', 'notAMember')),
        isA<HouseholdFailure>().having(
          (value) => value.problem,
          'problem',
          HouseholdProblem.notAMember,
        ),
      );
    });

    test('no reason at all falls back to the gRPC code, as elsewhere', () {
      expect(
        failureFromFrameCallable(refusal('unavailable', null)),
        isA<UnavailableFailure>(),
      );
    });
  });
}
