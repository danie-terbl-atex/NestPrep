import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// `ENG-22`: nothing we log or report identifies anybody.
///
/// This is a promise about a family's data, including children's, and it is the
/// kind of promise that is kept by everybody remembering it until one person
/// does not. The failure is invisible in review — `AppLog.failure('household
/// $householdId', …)` reads perfectly reasonably — and invisible at runtime,
/// because a log line nobody reads is still a log line somebody could.
///
/// So this checks the call sites rather than trusting them.
void main() {
  final dartFiles = Directory('lib')
      .listSync(recursive: true)
      .whereType<File>()
      .where((file) => file.path.endsWith('.dart'))
      .where((file) => !file.path.endsWith('.g.dart'))
      .where((file) => !file.path.endsWith('.freezed.dart'))
      .toList();

  /// Every argument of every call to [name], as written in the source.
  List<({String where, String argument})> callsTo(String name) {
    final found = <({String where, String argument})>[];
    final call = RegExp('$name\\(([^;]*?)\\)\\s*[;,)]', dotAll: true);
    for (final file in dartFiles) {
      final source = file.readAsStringSync();
      for (final match in call.allMatches(source)) {
        final line =
            '\n'.allMatches(source.substring(0, match.start)).length + 1;
        found.add((
          where: '${file.path}:$line',
          argument: match.group(1)!.replaceAll(RegExp(r'\s+'), ' ').trim(),
        ));
      }
    }
    return found;
  }

  test('it can see the calls it is checking', () {
    expect(
      callsTo('AppLog.failure'),
      isNotEmpty,
      reason: 'the logger is called somewhere, or this test checks nothing',
    );
  });

  test('a log line is never built out of somebody\'s data', () {
    final offences = [
      for (final call in callsTo('AppLog.failure'))
        // An interpolation is the whole risk: a literal cannot carry a name, a
        // household id or an invite code, and an interpolation can carry all
        // three without anybody noticing.
        if (call.argument.contains(r'$'))
          '${call.where}  AppLog.failure(${call.argument})',
    ];

    expect(
      offences,
      isEmpty,
      reason:
          'pass the *kind* of thing that failed, never the thing — the '
          'SDK code is enough to find it again (`ENG-22`)',
    );
  });

  test('the logger itself never puts the error into the message', () {
    final source = File('lib/shared/log/app_log.dart').readAsStringSync();
    final message = RegExp(r"developer\.log\(\s*'([^']*)'").firstMatch(source);

    expect(message, isNotNull, reason: 'the log call changed shape');
    expect(
      message!.group(1),
      isNot(contains(r'$error')),
      reason:
          'an SDK error message can carry a document path, and a document '
          'path carries a household id',
    );
  });

  group('what Crashlytics is told about a person', () {
    test('is a member id and nothing else', () {
      final calls = callsTo('CrashReporting.setMember');
      expect(calls, isNotEmpty);

      for (final call in calls) {
        expect(
          call.argument,
          contains('memberId'),
          reason:
              '${call.where}: the member id is the household\'s own opaque '
              'key and says nothing about a person; a uid, a name or an email '
              'would each say something',
        );
      }
    });

    test('and no custom key carries anything at all', () {
      expect(
        callsTo('setCustomKey'),
        isEmpty,
        reason:
            'a custom key is a free-text field on every crash report; '
            'there is no use for one here that ENG-22 would allow',
      );
    });
  });
}
