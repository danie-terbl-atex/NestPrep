import 'dart:io';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/calendar_sync/data/calendar_sync_failure_mapper.dart';
import 'package:nestprep/features/calendar_sync/model/calendar_provider.dart';
import 'package:nestprep/features/calendar_sync/model/connection_status.dart';
import 'package:nestprep/shared/copy/app_copy.dart';
import 'package:nestprep/shared/copy/calendar_sync_copy.dart';
import 'package:nestprep/shared/failure/app_failure.dart';

/// Calendar sync's three lists that are written down in both languages
/// (calendar ADR-0003): the refusals a Function sends, the statuses it leaves
/// on a connection, and the providers it stores. Each test reads the server's
/// own source, so the two cannot drift without something going red — the
/// lesson on contracts between two languages.
void main() {
  final errorsFile = File('../functions/src/calendar_sync/errors.ts');
  final documentsFile = File(
    '../functions/src/calendar_sync/sync_documents.ts',
  );

  Set<String> keysOf(String source, String start, String end) {
    final block = source.substring(
      source.indexOf(start),
      source.indexOf(end, source.indexOf(start)),
    );
    return RegExp(
      r'^\s{2}(\w+):',
      multiLine: true,
    ).allMatches(block).map((match) => match.group(1)!).toSet();
  }

  Set<String> stringsOf(String source, String constant) {
    final start = source.indexOf('$constant = [');
    final block = source.substring(start, source.indexOf('] as const', start));
    return RegExp("'(\\w+)'")
        .allMatches(block)
        .map((match) => match.group(1)!)
        .toSet();
  }

  Set<String> refusals() => keysOf(
    errorsFile.readAsStringSync(),
    'CALENDAR_SYNC_REFUSALS = {',
    '} as const satisfies',
  );

  AppFailure mapped(String reason) => failureFromCalendarSyncCallable(
    FirebaseFunctionsException(
      code: 'failed-precondition',
      message: 'for the log, not for a person',
      details: {'reason': reason},
    ),
  );

  test('the server source is where this test thinks it is', () {
    expect(errorsFile.existsSync(), isTrue);
    expect(documentsFile.existsSync(), isTrue);
    expect(refusals(), isNotEmpty);
  });

  test('every refusal the server can send, the client can name', () {
    final known = {
      for (final problem in CalendarSyncProblem.values) problem.name,
      for (final problem in HouseholdProblem.values) problem.name,
    };
    expect(refusals().difference(known), isEmpty);
  });

  test('and each becomes a sentence, never the reason itself', () {
    for (final reason in refusals()) {
      final copy = AppCopy.failure(mapped(reason));
      expect(copy.trim(), isNotEmpty, reason: reason);
      expect(copy, isNot(contains(reason)), reason: reason);
    }
  });

  test('a refusal only the client raises is not one the server lost', () {
    // `couldNotOpenBrowser` is the phone saying no, not a Function.
    final serverOnly = {
      for (final problem in CalendarSyncProblem.values)
        if (problem != CalendarSyncProblem.couldNotOpenBrowser) problem.name,
    };
    expect(serverOnly.difference(refusals()), isEmpty);
  });

  test('membership refusals keep the household’s words', () {
    expect(
      AppCopy.failure(mapped('notAMember')),
      AppCopy.householdProblem(HouseholdProblem.notAMember),
    );
  });

  test('every status a connection can be left in is one the screen words', () {
    final server = stringsOf(
      documentsFile.readAsStringSync(),
      'CONNECTION_STATUSES',
    );
    final client = {for (final status in ConnectionStatus.values) status.name};
    expect(server, client);
    for (final status in ConnectionStatus.values) {
      expect(
        CalendarSyncCopy.status(status, syncedAgo: null, eventCount: 0),
        isNot(contains(status.name)),
      );
    }
  });

  test('and every provider it stores is one the client knows', () {
    final server = stringsOf(documentsFile.readAsStringSync(), 'PROVIDERS');
    expect(server, {
      for (final provider in CalendarProvider.values) provider.name,
    });
  });
}
