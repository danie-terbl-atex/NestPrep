import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/design/tokens/nest_member_palette.dart';
import 'package:nestprep/features/household/model/birthday.dart';
import 'package:nestprep/features/household/model/member.dart';
import 'package:nestprep/shared/time/calendar_date.dart';

/// A birthday's stored shape is written down in two languages: `Birthday.iso`
/// in Dart, and a pair of regular expressions in `firestore.rules`. Nothing
/// else compares them.
///
/// Drift here is the quiet kind. The rules refuse the write, the client shows
/// "You cannot do that", and every Dart test still passes — because the Dart
/// side alone is perfectly consistent with itself. It is the same failure the
/// refusal contract was written for
/// (`lessons/a-contract-between-two-languages-needs-a-test-that-reads-both`),
/// so this reads the rules' own source rather than a copy of it.
void main() {
  final rulesFile = File('../firestore.rules');

  /// The whole of `isBirthday`, closing brace and all. It cannot stop at the
  /// first `}`: the patterns themselves contain `{4}` and `{2}`.
  String isBirthdayFunction() {
    final source = rulesFile.readAsStringSync();
    final start = source.indexOf('function isBirthday(value) {');
    expect(start, isNot(-1), reason: 'the rules no longer check a birthday');
    final end = source.indexOf('\n    }', start);
    expect(end, isNot(-1), reason: 'the function never closes');
    return source.substring(start, end);
  }

  /// The patterns the rules accept, read out of the rules.
  List<RegExp> patternsTheRulesAccept() => [
    for (final match in RegExp(
      r"matches\('([^']+)'\)",
    ).allMatches(isBirthdayFunction()))
      RegExp(match.group(1)!),
  ];

  bool rulesAccept(String stored) =>
      patternsTheRulesAccept().any((pattern) => pattern.hasMatch(stored));

  /// Both `hasOnly` lists under `match /members/{memberId}`, read from the
  /// household's own rules partial (foundation ADR-0012), where that block is
  /// the last thing in the file.
  List<Set<String>> keysTheMemberRulesAllow() {
    final source = File('../rules/firestore/household/household.rules')
        .readAsStringSync();
    final block = source.substring(
      source.indexOf('match /members/{memberId} {'),
    );
    return [
      for (final match in RegExp(
        r'(?:hasOnly|onlyChanged)\(\s*\n?\s*\[([^\]]+)\]',
      ).allMatches(block))
        RegExp(r"'(\w+)'")
            .allMatches(match.group(1)!)
            .map((m) => m.group(1)!)
            .toSet(),
    ];
  }

  test('it can see both sides of the contract', () {
    expect(rulesFile.existsSync(), isTrue);
    expect(
      patternsTheRulesAccept(),
      hasLength(2),
      reason: 'a birthday has two shapes: with a year and without',
    );
    expect(keysTheMemberRulesAllow(), hasLength(2), reason: 'create, update');
  });

  test('the rules name the field the model writes', () {
    final written = const Member(
      id: 'm',
      displayName: 'Ada',
      color: MemberColor.teal,
      roleName: 'member',
    ).toJson().keys.toSet();

    for (final allowed in keysTheMemberRulesAllow()) {
      expect(
        allowed,
        contains('birthday'),
        reason: 'a key the model writes and the rules do not name is refused',
      );
    }
    expect(written, contains('birthday'));
  });

  test('every birthday the model can write, the rules accept', () {
    final everyShape = <Birthday>[
      for (var month = 1; month <= 12; month++) ...[
        Birthday(month: month, day: 1),
        Birthday(month: month, day: CalendarDate.daysIn(2000, month)),
        Birthday(year: 1901, month: month, day: 1),
        Birthday(
          year: 2024,
          month: month,
          day: CalendarDate.daysIn(2024, month),
        ),
      ],
      Birthday(month: 2, day: 29),
      Birthday(year: 2016, month: 2, day: 29),
    ];

    final refused = [
      for (final birthday in everyShape)
        if (!rulesAccept(birthday.iso)) birthday.iso,
    ];

    expect(
      refused,
      isEmpty,
      reason:
          'the client would write these and the rules would deny the write, '
          'which reaches a person as "You cannot do that"',
    );
  });

  test('and what the rules refuse, the model could never have written', () {
    for (final wrong in [
      '',
      'yesterday',
      '30-04-1952',
      '1952-13-30',
      '1952-04-32',
      '--00-30',
      '--13-01',
      '1952-4-3',
    ]) {
      expect(rulesAccept(wrong), isFalse, reason: '$wrong is not a birthday');
      expect(() => Birthday.parse(wrong), throwsA(isA<FormatException>()));
    }
  });

  test('the one check the rules cannot make is the one the model does', () {
    // Rules count to 31 without knowing which months have 31 days.
    expect(
      rulesAccept('1952-02-31'),
      isTrue,
      reason: 'the rules language cannot count the days in a month',
    );
    expect(
      () => Birthday.parse('1952-02-31'),
      throwsA(isA<FormatException>()),
      reason: 'so the client is the one that refuses it (`BE-03`)',
    );
  });
}
