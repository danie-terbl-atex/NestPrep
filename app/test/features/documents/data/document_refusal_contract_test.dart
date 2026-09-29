import 'dart:io';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/documents/data/document_failure_mapper.dart';
import 'package:nestprep/shared/copy/app_copy.dart';
import 'package:nestprep/shared/failure/app_failure.dart';
import 'package:nestprep/shared/failure/storage_failure_mapper.dart';

/// `BE-04`, across the two languages that share it, for the documents
/// callables — the same contract the household one already holds, and the same
/// failure mode: a reason the client has never heard of is not an error, it is
/// "Something went wrong" in place of copy the app already has.
///
/// This reads the server's own source rather than a copy of it, so the two
/// cannot drift without something going red.
void main() {
  final errorsFile = File('../functions/src/documents/errors.ts');

  /// The keys of `DOCUMENT_REFUSALS`, read out of the TypeScript.
  Set<String> refusalsDeclaredByTheServer() {
    final source = errorsFile.readAsStringSync();
    final block = source.substring(
      source.indexOf('DOCUMENT_REFUSALS = {'),
      source.indexOf('} as const satisfies'),
    );
    return RegExp(
      r'^\s{2}(\w+):',
      multiLine: true,
    ).allMatches(block).map((match) => match.group(1)!).toSet();
  }

  /// Every reason this build can turn into a sentence — the documents problems
  /// plus the household ones, because two of the server's reasons are about
  /// household membership and say so in the household's words.
  Set<String> reasonsTheClientCanName() => {
    for (final problem in DocumentProblem.values) problem.name,
    for (final problem in HouseholdProblem.values) problem.name,
  };

  AppFailure mapped(String reason) => failureFromDocumentCallable(
    FirebaseFunctionsException(
      code: 'permission-denied',
      message: 'for the log, not for a person',
      details: {'reason': reason},
    ),
  );

  test('the server source is where this test thinks it is', () {
    expect(
      errorsFile.existsSync(),
      isTrue,
      reason:
          'if errors.ts moved, this contract lost its home — point the test '
          'at the new one rather than deleting it',
    );
    expect(
      refusalsDeclaredByTheServer(),
      isNotEmpty,
      reason: 'parsing found nothing, which means the shape changed',
    );
  });

  test('every reason the server can send, the client can name', () {
    final unknown = refusalsDeclaredByTheServer().difference(
      reasonsTheClientCanName(),
    );

    expect(
      unknown,
      isEmpty,
      reason:
          'the app would show "Something went wrong" for a refusal it could '
          'have explained (`BE-04`)',
    );
  });

  test('and every one of them turns into a sentence somebody can read', () {
    for (final reason in refusalsDeclaredByTheServer()) {
      final copy = AppCopy.failure(mapped(reason));
      expect(copy.trim(), isNotEmpty, reason: '$reason has no words');
      expect(copy, isNot(contains(reason)), reason: 'that is our vocabulary');
    }
  });

  test('a membership refusal keeps the household"s own words', () {
    // `notAMember` means the same thing whichever callable said it. A second
    // sentence for it would be two ways of saying one thing.
    expect(
      AppCopy.failure(mapped('notAMember')),
      AppCopy.householdProblem(HouseholdProblem.notAMember),
    );
    expect(
      AppCopy.failure(mapped('notAnAdmin')),
      AppCopy.householdProblem(HouseholdProblem.notAnAdmin),
    );
  });

  test('a documents refusal gets the documents words', () {
    expect(
      AppCopy.failure(mapped('folderNotEmpty')),
      AppCopy.documentProblem(DocumentProblem.folderNotEmpty),
    );
  });

  test('a reason from a Function newer than this build is not a crash', () {
    final failure = mapped('somethingInventedLater');
    expect(failure, isA<PermissionDeniedFailure>());
    expect(AppCopy.failure(failure), isNotEmpty);
  });

  test('a refusal with no reason at all still becomes a failure', () {
    for (final (code, expected) in [
      ('unauthenticated', HouseholdFailure),
      ('permission-denied', PermissionDeniedFailure),
      ('unavailable', UnavailableFailure),
      ('not-found', NotFoundFailure),
      ('internal', UnknownFailure),
    ]) {
      final failure = failureFromDocumentCallable(
        FirebaseFunctionsException(
          code: code,
          message: 'for the log, not for a person',
        ),
      );
      expect(failure.runtimeType, expected, reason: code);
      expect(AppCopy.failure(failure), isNotEmpty);
    }
  });

  group('Cloud Storage has its own codes, and they are mapped too', () {
    // Storage reports `storage/...` rather than the gRPC codes Firestore uses,
    // so the shared mapper cannot read them at all.
    for (final (code, expected) in [
      ('storage/unauthorized', PermissionDeniedFailure),
      ('storage/canceled', DocumentFailure),
      ('storage/object-not-found', NotFoundFailure),
      ('storage/unauthenticated', SessionExpiredFailure),
      ('storage/retry-limit-exceeded', UnavailableFailure),
      ('storage/quota-exceeded', UnknownFailure),
    ]) {
      test('$code becomes $expected', () {
        final failure = failureFromStorage(
          FirebaseException(plugin: 'firebase_storage', code: code),
        );
        expect(failure.runtimeType, expected);
        expect(AppCopy.failure(failure), isNotEmpty);
        expect(AppCopy.failure(failure), isNot(contains(code)));
      });
    }

    test('a cancelled upload is named as one, not as a permission problem', () {
      final failure = failureFromStorage(
        FirebaseException(plugin: 'firebase_storage', code: 'storage/canceled'),
      );
      expect(
        (failure as DocumentFailure).problem,
        DocumentProblem.uploadCancelled,
      );
    });

    test('something that is not a Firebase error is still handled', () {
      expect(failureFromStorage(StateError('bad')), isA<UnknownFailure>());
      expect(failureFromStorage('a bare string'), isA<UnknownFailure>());
    });

    test('a failure that is already ours passes straight through', () {
      const already = PermissionDeniedFailure();
      expect(failureFromStorage(already), same(already));
    });
  });
}
