import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/home_care/model/language/helper_language.dart';
import 'package:nestprep/features/home_care/model/routine/room_routine.dart';
import 'package:nestprep/features/home_care/model/routine/routine_cadence.dart';
import 'package:nestprep/features/home_care/model/stock_level.dart';
import 'package:nestprep/shared/failure/app_failure.dart';

/// Home care's V2 words are written down in three languages — the app, the
/// rules and the Functions — and a contract between two languages needs a
/// test that reads both (the vault lesson of that name). A cadence the rules
/// do not know is a routine nobody can save; a language the Function does
/// not know is a helper who reads English for ever; a refusal the app does
/// not know is a raw error on her screen.
void main() {
  final routineRules = File(
    '../rules/firestore/household/home_care_routines.rules',
  ).readAsStringSync();
  final languageRules = File(
    '../rules/firestore/household/home_care_language.rules',
  ).readAsStringSync();
  final productRules = File(
    '../rules/firestore/household/home_care.rules',
  ).readAsStringSync();
  final languages = File(
    '../functions/src/home_care/languages.ts',
  ).readAsStringSync();
  final restock = File(
    '../functions/src/home_care/restock_decision.ts',
  ).readAsStringSync();
  final errors = File(
    '../functions/src/home_care/errors.ts',
  ).readAsStringSync();

  /// The quoted words of the first `[...]` after [anchor] in [source].
  Set<String> wordsAfter(String source, String anchor) {
    final start = source.indexOf(anchor);
    expect(start, isNot(-1), reason: 'no longer says "$anchor"');
    final list = RegExp(
      r'\[([^\]]*)\]',
    ).firstMatch(source.substring(start))!.group(1)!;
    return {
      for (final match in RegExp("'(\\w+)'").allMatches(list)) match.group(1)!,
    };
  }

  test('the rules know the same cadences as the app', () {
    expect(wordsAfter(routineRules, 'routine.cadence in'), {
      for (final cadence in RoutineCadence.values) cadence.name,
    });
  });

  test('the rules keep as many items as the app offers', () {
    final limit = RegExp(
      r'routine\.items\.size\(\) <= (\d+)',
    ).firstMatch(routineRules)!.group(1)!;
    expect(int.parse(limit), RoomRoutine.itemLimit);
  });

  test('the rules, the Function and the app know the same stock levels', () {
    final app = {for (final level in StockLevel.values) level.name};
    expect(wordsAfter(productRules, 'data.stock in'), app);
    expect(wordsAfter(restock, 'STOCK_LEVELS ='), app);
  });

  test('the rules, the Function and the app know the same languages', () {
    final app = {for (final language in HelperLanguage.values) language.code};
    expect(wordsAfter(languageRules, 'data.language in'), app);
    expect(wordsAfter(languages, 'HELPER_LANGUAGES ='), app);
    expect(wordsAfter(languages, 'TARGET_LANGUAGES ='), {
      for (final language in HelperLanguage.values)
        if (language.needsTranslation) language.code,
    });
  });

  test('every refusal the Function gives, the app has words for', () {
    final start = errors.indexOf('HOME_CARE_REFUSALS = {');
    final end = errors.indexOf('} as const', start);
    final reasons = {
      for (final match in RegExp(
        r'^\s{2}(\w+):',
        multiLine: true,
      ).allMatches(errors.substring(start, end)))
        match.group(1)!,
    };
    expect(reasons, isNotEmpty);
    final known = {
      for (final problem in HomeCareProblem.values) problem.name,
      for (final problem in HouseholdProblem.values) problem.name,
    };
    expect(reasons.difference(known), isEmpty);
  });
}
