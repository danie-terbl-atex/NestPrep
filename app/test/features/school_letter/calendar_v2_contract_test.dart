import 'dart:io';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/school_letter/data/school_letter_failure_mapper.dart';
import 'package:nestprep/features/school_letter/model/letter_file.dart';
import 'package:nestprep/shared/failure/app_failure.dart';
import 'package:nestprep/shared/flags/feature_flag.dart';

/// The words the app and the Functions both write down for AI and for snap a
/// school letter — a contract between two languages needs a test that reads
/// both (the vault lesson). A reason renamed on one side is a refusal the app
/// shows as "something went wrong"; a flag renamed is a switch that stops
/// switching.
void main() {
  final aiRefusals = File('../functions/src/ai/ai_refusals.ts')
      .readAsStringSync();
  final letterRefusals = File('../functions/src/school_letter/errors.ts')
      .readAsStringSync();
  final letterSchemas = File('../functions/src/school_letter/schemas.ts')
      .readAsStringSync();
  final flags = File('../functions/src/shared/feature_flags.ts')
      .readAsStringSync();

  /// The keys of the `{ … }` block that follows [anchor].
  Set<String> keysAfter(String source, String anchor) {
    final start = source.indexOf(anchor);
    expect(start, isNot(-1), reason: 'no longer says "$anchor"');
    final block = source.substring(start, source.indexOf('} as const', start));
    return {
      for (final match in RegExp(
        r'^\s+(\w+): \[',
        multiLine: true,
      ).allMatches(block))
        match.group(1)!,
    };
  }

  test('every AI refusal the server sends has words in the app', () {
    expect(keysAfter(aiRefusals, 'AI_REFUSALS ='), {
      for (final problem in AiProblem.values) problem.name,
    });
  });

  test('every letter refusal the server sends has words in the app', () {
    final server = keysAfter(letterRefusals, 'SCHOOL_LETTER_REFUSALS =');
    final app = {
      for (final problem in SchoolLetterProblem.values) problem.name,
    };
    expect(app.containsAll(server), isTrue, reason: '$server vs $app');
  });

  test('the file kinds and the size limit agree', () {
    for (final kind in LetterKind.values) {
      expect(letterSchemas, contains("'${kind.mimeType}'"));
    }
    expect(letterSchemas, contains('MAX_LETTER_BYTES = 4 * 1024 * 1024'));
    expect(LetterFile.maxBytes, 4 * 1024 * 1024);
  });

  test('the server’s switch is one the app knows by the same name', () {
    expect(flags, contains("'${FeatureFlag.snapSchoolLetter.key}'"));
  });

  group('a refusal from the callable', () {
    AppFailure mapped(String code, [String? reason]) =>
        failureFromLetterCallable(
          FirebaseFunctionsException(
            code: code,
            message: 'server words',
            details: reason == null ? null : {'reason': reason},
          ),
        );

    test('keeps its own reason, the AI’s, and the calendar grant’s', () {
      expect(
        mapped('invalid-argument', 'letterTooLarge'),
        isA<SchoolLetterFailure>(),
      );
      expect(
        mapped('resource-exhausted', 'aiLimitReached'),
        isA<AiFailure>().having(
          (failure) => failure.problem,
          'problem',
          AiProblem.aiLimitReached,
        ),
      );
      expect(
        mapped('permission-denied', 'calendarNotShared'),
        isA<CalendarSyncFailure>(),
      );
      expect(
        mapped('permission-denied', 'notAMember'),
        isA<HouseholdFailure>(),
      );
    });

    test('falls back on its code when it has no reason', () {
      expect(mapped('unauthenticated'), isA<HouseholdFailure>());
      expect(mapped('deadline-exceeded'), isA<AiFailure>());
      expect(mapped('unavailable'), isA<UnavailableFailure>());
      expect(mapped('internal'), isA<UnknownFailure>());
    });
  });
}
