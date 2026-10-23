import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/design/tokens/nest_member_palette.dart';
import 'package:nestprep/features/two_homes/data/firestore_two_homes_repository.dart';
import 'package:nestprep/features/two_homes/data/two_homes_directory.dart';
import 'package:nestprep/features/two_homes/model/change_request.dart';
import 'package:nestprep/features/two_homes/model/co_parent_link.dart';
import 'package:nestprep/features/two_homes/model/custody_schedule.dart';
import 'package:nestprep/features/two_homes/model/custody_side.dart';
import 'package:nestprep/features/two_homes/model/handover_note.dart';
import 'package:nestprep/shared/failure/app_failure.dart';

/// Two homes is written down in three languages: the app, the co-parenting
/// Functions and the rules partial (household ADR-0004). Written twice is a
/// contract, and a contract between two languages needs a test that reads
/// both — `lessons/a-contract-between-two-languages-needs-a-test-that-reads-both`.
/// Rename a pattern on one side and every code the other side makes is
/// refused; add a refusal to the server and the app says "Something went
/// wrong" where it had words.
void main() {
  String read(String path) => File(path).readAsStringSync();
  final errors = read('../functions/src/coparent/errors.ts');
  final schedule = read('../functions/src/coparent/schedule_schema.ts');
  final schemas = read('../functions/src/coparent/schemas.ts');
  final linkContext = read('../functions/src/coparent/link_context.ts');
  final answer = read('../functions/src/coparent/answer_coparent_change.ts');
  final refs = read('../functions/src/coparent/coparent_refs.ts');
  final rules = read('../rules/firestore/household/coparent.rules');

  Set<String> wordsAfter(String source, String anchor) {
    final start = source.indexOf(anchor);
    expect(start, isNot(-1), reason: 'no longer says "$anchor"');
    final list = RegExp(r'\[([^\]]*)\]')
        .firstMatch(source.substring(start))!
        .group(1)!;
    return {
      for (final match in RegExp("'(\\w+)'").allMatches(list)) match.group(1)!,
    };
  }

  int numberAfter(String source, String anchor) {
    final start = source.indexOf(anchor);
    expect(start, isNot(-1), reason: 'no longer says "$anchor"');
    return int.parse(
      RegExp(r'(\d+)').firstMatch(source.substring(start))!.group(1)!,
    );
  }

  test('every refusal the server sends, the app has words for', () {
    final reasons = {
      for (final match in RegExp(
        r'^  (\w+): \[',
        multiLine: true,
      ).allMatches(errors))
        match.group(1)!,
    };
    final app = {
      ...CoParentProblem.values.map((problem) => problem.name),
      // The household's own words, reused for the same facts.
      ...HouseholdProblem.values.map((problem) => problem.name),
    };
    expect(reasons, isNotEmpty);
    expect(reasons.difference(app), isEmpty);
    // And no problem the app has words for has stopped being sent.
    expect(
      CoParentProblem.values
          .map((problem) => problem.name)
          .toSet()
          .difference(reasons),
      isEmpty,
    );
  });

  test('the same patterns, sides and home colours', () {
    expect(wordsAfter(schedule, 'PATTERNS ='), {
      for (final pattern in CustodyPattern.values) pattern.name,
    });
    expect(wordsAfter(schedule, 'SIDES ='), {
      for (final side in CustodySide.values) side.name,
    });
    expect(wordsAfter(schedule, 'HOME_COLORS ='), {
      for (final color in MemberColor.values) color.name,
    });
  });

  test('the same statuses for a link and a request', () {
    expect(wordsAfter(linkContext, 'LINK_STATUSES ='), {
      for (final status in LinkStatus.values) status.name,
    });
    // A request is pending, then whatever its answer left it, or closed.
    for (final status in RequestStatus.values) {
      expect(
        '$answer${read('../functions/src/coparent/end_coparent_link.ts')}'
        '${read('../functions/src/coparent/change_rules.ts')}'
        '${read('../functions/src/coparent/propose_coparent_change.ts')}',
        contains("'${status.name}'"),
        reason: '${status.name} is never written',
      );
    }
  });

  test('the same answers', () {
    expect(wordsAfter(schemas, 'answer: z.enum('), {
      for (final each in ChangeAnswer.values) each.name,
    });
  });

  test('the same limits', () {
    expect(numberAfter(schemas, 'MAX_SWAP_DAYS ='), ChangeRequest.maxSwapDays);
    expect(numberAfter(schemas, 'MAX_HANDOVER_ITEMS ='), HandoverNote.maxItems);
    expect(
      numberAfter(schedule, 'MAX_CYCLE_WEEKS ='),
      CustodySchedule.maxCycleWeeks,
    );
  });

  test('the same collection names, in the Functions and the rules', () {
    for (final name in [
      FirestoreTwoHomesRepository.links,
      FirestoreTwoHomesRepository.handovers,
      FirestoreTwoHomesRepository.requests,
    ]) {
      expect(refs, contains("'$name'"), reason: name);
      expect(rules, contains('/$name/'), reason: name);
    }
  });
}
