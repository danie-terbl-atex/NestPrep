import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/nanny_hub/data/nanny_paths.dart';
import 'package:nestprep/features/nanny_hub/model/contact_kind.dart';
import 'package:nestprep/features/nanny_hub/model/handover_kind.dart';
import 'package:nestprep/features/nanny_hub/model/handover_mood.dart';
import 'package:nestprep/features/nanny_hub/model/nanny_limits.dart';
import 'package:nestprep/features/nanny_hub/model/shift_moment.dart';
import 'package:nestprep/shared/failure/app_failure.dart';

/// The nanny hub's words, limits and names are written down in three
/// languages: the app, the rules partial and `endNannyShift`. Written down
/// twice is a contract, and a contract between two languages needs a test
/// that reads both (the vault lesson of that name). Add a kind of entry to the
/// app and not the rules and every one is refused; rename a moment in the rules
/// and its checklist is never written again.
void main() {
  final rules = File('../rules/firestore/household/nanny_hub.rules')
      .readAsStringSync();
  final storageRules = File('../storage.rules').readAsStringSync();
  final summary = File('../functions/src/nanny_hub/shift_summary.ts')
      .readAsStringSync();
  final refs = File('../functions/src/nanny_hub/nanny_refs.ts')
      .readAsStringSync();
  final errors = File('../functions/src/nanny_hub/errors.ts')
      .readAsStringSync();

  /// The quoted words of the first `[...]` after [anchor] in [source].
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
      RegExp(r'<= (\d+)').firstMatch(source.substring(start))!.group(1)!,
    );
  }

  group('the vocabularies', () {
    test('the rules, the summary and the app know the same kinds of entry', () {
      final app = {for (final kind in HandoverKind.values) kind.name};
      expect(wordsAfter(rules, "data.kind in ['meal'"), app);
      expect(wordsAfter(summary, 'ENTRY_KINDS ='), app);
    });

    test('and the same moods', () {
      final app = {for (final mood in HandoverMood.values) mood.name};
      expect(wordsAfter(rules, 'data.mood in'), app);
      expect(wordsAfter(summary, 'MOODS ='), app);
    });

    test('and the same five moments, which the rules and the summary read', () {
      final app = {for (final moment in ShiftMoment.values) moment.name};
      expect(wordsAfter(rules, 'moment in'), app);
      expect(wordsAfter(refs, 'MOMENTS ='), app);
    });

    test('and the same kinds of contact', () {
      expect(wordsAfter(rules, 'data.kind in [\'parent\''), {
        for (final kind in ContactKind.values) kind.name,
      });
    });

    test('and the same collection names', () {
      for (final name in [
        NannyPaths.cards,
        NannyPaths.contacts,
        NannyPaths.home,
        NannyPaths.guide,
        NannyPaths.rules,
        NannyPaths.checklists,
        NannyPaths.shifts,
        NannyPaths.entries,
        NannyPaths.summaries,
      ]) {
        expect(rules, contains('match /$name/'), reason: name);
      }
      for (final name in [
        NannyPaths.shifts,
        NannyPaths.entries,
        NannyPaths.summaries,
        NannyPaths.checklists,
      ]) {
        expect(refs, contains("'$name'"), reason: name);
      }
    });
  });

  group('the limits', () {
    test('a card’s', () {
      expect(
        numberAfter(rules, "data.get('routines', []).size()"),
        NannyLimits.routines,
      );
      expect(
        numberAfter(rules, "data.get('comfortItems', []).size()"),
        NannyLimits.comfortItems,
      );
      expect(
        rules,
        contains("data.get('settling', null), ${NannyLimits.careNote}"),
      );
    });

    test('the sheet’s, a contact’s, a place’s and a rule’s', () {
      expect(rules, contains("'address', null), ${NannyLimits.address}"));
      expect(
        rules,
        contains("'medicalAidScheme', null), ${NannyLimits.medicalAidScheme}"),
      );
      expect(
        rules,
        contains("'medicalAidNumber', null), ${NannyLimits.medicalAidNumber}"),
      );
      expect(rules, contains('data.name, ${NannyLimits.contactName}'));
      expect(rules, contains("'note', null), ${NannyLimits.contactNote}"));
      expect(rules, contains('data.title, ${NannyLimits.spotTitle}'));
      expect(rules, contains("'note', null), ${NannyLimits.spotNote}"));
      expect(rules, contains('data.text, ${NannyLimits.ruleText}'));
      expect(rules, contains(r"'^[+0-9 ()-]{3,20}$'"));
      expect(NannyLimits.phonePattern.pattern, r'^[+0-9 ()-]{3,20}$');
    });

    test('a checklist’s, a shift’s and an entry’s', () {
      expect(
        numberAfter(rules, 'request.resource.data.items.size()'),
        NannyLimits.checklistItems,
      );
      expect(
        numberAfter(rules, 'request.resource.data.ticks.size()'),
        NannyLimits.ticks,
      );
      expect(rules, contains("'note', null), ${NannyLimits.entryNote}"));
      expect(
        numberAfter(rules, 'data.childIds.size()'),
        NannyLimits.entryChildren,
      );
    });

    test('a photo’s, which only Storage can see', () {
      expect(
        storageRules,
        contains('request.resource.size <= ${NannyLimits.photoBytes}'),
      );
      expect(NannyLimits.photoBytes, 2 * 1024 * 1024);
    });
  });

  test('every refusal the Function sends has words in the app', () {
    final sent = {
      for (final match in RegExp(
        r'^\s+(\w+): \[',
        multiLine: true,
      ).allMatches(errors))
        match.group(1)!,
    };
    expect(sent, contains('shiftAlreadyEnded'));
    final known = {
      for (final problem in NannyHubProblem.values) problem.name,
      for (final problem in HouseholdProblem.values) problem.name,
    };
    expect(sent.difference(known), isEmpty);
  });
}
