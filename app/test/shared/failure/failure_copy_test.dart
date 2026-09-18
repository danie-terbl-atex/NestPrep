import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/shared/copy/app_copy.dart';
import 'package:nestprep/shared/failure/app_failure.dart';
import 'package:nestprep/shared/failure/firebase_failure_mapper.dart';

/// `FE-09`: nothing user-facing ever shows a raw error. That is a promise about
/// *every* failure the app can produce, not the ones a test happened to reach,
/// so this walks the whole set — and fails the day somebody adds a case to an
/// enum and forgets the words that go with it.
void main() {
  /// Every `AppFailure` the app can construct. A new one added below the line
  /// without a row here is the point: `AppCopy.failure`'s switch is exhaustive,
  /// so the compiler catches it there, and this catches whether it got *words*.
  final everyFailure = <AppFailure>[
    const PermissionDeniedFailure(),
    const UnavailableFailure(),
    const NotFoundFailure(),
    const SessionExpiredFailure(),
    UnknownFailure(Exception('a socket closed somewhere')),
    for (final problem in SignInProblem.values) SignInFailure(problem),
    for (final problem in HouseholdProblem.values) HouseholdFailure(problem),
  ];

  /// Words that mean something to us and nothing to a person holding a phone.
  const leakedInternals = [
    'exception',
    'null',
    'firebase',
    'firestore',
    'permission-denied',
    'unauthenticated',
    'stack',
    'error:',
    '_',
  ];

  group('every failure has words a person can read', () {
    for (final failure in everyFailure) {
      final name = failure.runtimeType.toString();
      final label = switch (failure) {
        SignInFailure(:final problem) => '$name.${problem.name}',
        HouseholdFailure(:final problem) => '$name.${problem.name}',
        _ => name,
      };

      test(label, () {
        final copy = AppCopy.failure(failure);

        expect(copy.trim(), isNotEmpty, reason: 'silence is not an answer');
        expect(
          copy,
          matches(RegExp(r'^[A-Z]')),
          reason: 'it is a sentence somebody reads',
        );
        expect(copy.trim(), endsWith('.'), reason: 'so is the full stop');

        for (final leak in leakedInternals) {
          expect(
            copy.toLowerCase(),
            isNot(contains(leak)),
            reason: '"$leak" is our vocabulary, not theirs (`FE-09`)',
          );
        }
      });
    }
  });

  test('no two problems a person can act on share the same words', () {
    // The two catch-alls are allowed to agree, and should: from the person's
    // side, an unrecognised household refusal and an unknown failure are the
    // same event — we do not know what happened. Everything else is a different
    // thing to do next, so saying the same words would be a support call nobody
    // could answer.
    const deliberateCatchAlls = {
      HouseholdProblem.unrecognised,
      SignInProblem.unknown,
    };
    final distinct = [
      for (final failure in everyFailure)
        if (!switch (failure) {
          HouseholdFailure(:final problem) => deliberateCatchAlls.contains(
            problem,
          ),
          SignInFailure(:final problem) => deliberateCatchAlls.contains(
            problem,
          ),
          UnknownFailure() => true,
          _ => false,
        })
          AppCopy.failure(failure),
    ];

    expect(distinct.toSet(), hasLength(distinct.length));
  });

  test('the catch-alls say the one honest thing, and say it the same way', () {
    final unknown = AppCopy.failure(UnknownFailure(Exception('x')));
    expect(
      AppCopy.failure(const HouseholdFailure(HouseholdProblem.unrecognised)),
      unknown,
      reason: 'two names for "we do not know" should not become two messages',
    );
  });

  test('the cancelled case still says something, because the banner shows', () {
    // The enum's comment says "say nothing"; the screen decides that, not the
    // copy. If the copy were empty the banner would be a blank rectangle.
    expect(
      AppCopy.failure(const SignInFailure(SignInProblem.cancelled)).trim(),
      isNotEmpty,
    );
  });

  group('Firebase errors become failures at the edge', () {
    for (final (code, expected) in [
      ('permission-denied', PermissionDeniedFailure),
      ('unavailable', UnavailableFailure),
      ('deadline-exceeded', UnavailableFailure),
      ('not-found', NotFoundFailure),
      ('unauthenticated', SessionExpiredFailure),
    ]) {
      test('$code becomes $expected', () {
        final failure = failureFromFirebase(
          FirebaseException(plugin: 'cloud_firestore', code: code),
        );
        expect(failure.runtimeType, expected);
        expect(AppCopy.failure(failure), isNotEmpty);
      });
    }

    test('a code we have never seen is unknown, not a crash', () {
      final failure = failureFromFirebase(
        FirebaseException(
          plugin: 'cloud_firestore',
          code: 'resource-exhausted',
        ),
      );
      expect(failure, isA<UnknownFailure>());
      expect(
        AppCopy.failure(failure),
        isNot(contains('resource-exhausted')),
        reason: 'the code goes to the log, never to the screen',
      );
    });

    test('something that is not a Firebase error at all is still handled', () {
      expect(failureFromFirebase(StateError('bad')), isA<UnknownFailure>());
      expect(failureFromFirebase('a bare string'), isA<UnknownFailure>());
    });

    test('a failure that is already ours passes straight through', () {
      const already = PermissionDeniedFailure();
      expect(failureFromFirebase(already), same(already));
    });
  });
}
