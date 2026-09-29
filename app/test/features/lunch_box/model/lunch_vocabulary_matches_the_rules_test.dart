import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/family_profiles/model/allergen.dart';
import 'package:nestprep/features/lunch_box/data/lunch_repository.dart';
import 'package:nestprep/features/lunch_box/model/lunch_favourite.dart';
import 'package:nestprep/features/lunch_box/model/lunch_feedback.dart';
import 'package:nestprep/features/lunch_box/model/lunch_item.dart';
import 'package:nestprep/features/lunch_box/model/lunch_plan.dart';
import 'package:nestprep/features/lunch_box/model/lunch_prep.dart';
import 'package:nestprep/features/lunch_box/model/lunch_slot.dart';

/// The slots, the allergen codes, the twenty-five slot keys, the limits and
/// the collection names are written in the app and again in the rules
/// partial. A contract between two languages needs a test that reads both
/// (the vault lesson of that name): add a slot to the app and not the rules
/// and every box using it is refused; a key the rules do not list is never
/// safety-checked.
void main() {
  // The feature's rules are two partials: the matches, and the checks every
  // plan write calls (lunch-box ADR-0010).
  final rules = [
    File('../rules/firestore/household/lunch_box.rules').readAsStringSync(),
    File('../rules/firestore/household/lunch_box_checks.rules')
        .readAsStringSync(),
  ].join('\n');
  final analytics = File(
    '../functions/src/product_analytics/analytics_documents.ts',
  ).readAsStringSync();
  final repository = File(
    'lib/features/lunch_box/data/firestore_lunch_repository.dart',
  ).readAsStringSync();
  String pathNamed(String constant) =>
      RegExp("static const $constant = '(\\w+)';")
          .firstMatch(repository)!
          .group(1)!;

  Set<String> quoted(String text) => {
    for (final match in RegExp("'([\\w-]+)'").allMatches(text)) match.group(1)!,
  };

  /// The quoted words in the first `[...]` after [anchor].
  Set<String> listAfter(String anchor) {
    final start = rules.indexOf(anchor);
    expect(start, isNot(-1), reason: 'the rules no longer say "$anchor"');
    return quoted(
      RegExp(r'\[([^\]]*)\]').firstMatch(rules.substring(start))!.group(1)!,
    );
  }

  test('the rules know exactly the allergens the app does', () {
    final codes = {for (final allergen in Allergen.values) allergen.name};
    expect(listAfter('function isLunchAllergens'), codes);
  });

  test('and exactly its five slots, for items and for go-to boxes', () {
    final slots = {for (final slot in LunchSlot.values) slot.name};
    expect(listAfter('data.slot in'), slots);
    expect(listAfter('function isLunchFavouritePicks'), slots);
  });

  test('and exactly its twenty-five slot keys, each safety-checked', () {
    expect(listAfter("data.get('slots', {}).keys().hasOnly("), {
      ...LunchPlan.allSlotKeys,
    });
    for (final key in LunchPlan.allSlotKeys) {
      expect(
        rules,
        contains("lunchPickIsSafe(slots['$key'], avoid)"),
        reason: 'rules cannot loop, so each slot is checked by name',
      );
    }
  });

  test('and exactly its two verdicts', () {
    expect(listAfter('verdict in'), {
      for (final verdict in LunchVerdict.values) verdict.name,
    });
  });

  test('the limits the app stops at are the ones the rules refuse past', () {
    expect(rules, contains('isLunchText(data.name, ${LunchItem.nameLimit})'));
    expect(
      rules,
      contains(
        "isLunchText(data.get('prepNote', null), ${LunchItem.prepNoteLimit})",
      ),
    );
    expect(
      rules,
      contains(
        'isLunchText(request.resource.data.name, ${LunchFavourite.nameLimit})',
      ),
    );
    expect(rules, contains('done.size() <= ${LunchPrep.doneLimit}'));
    expect(LunchRepository.planLimit, greaterThanOrEqualTo(9 * 10));
  });

  test(
    'the app, the rules and product-analytics name the same collections',
    () {
      for (final constant in [
        'itemsPath',
        'plansPath',
        'favouritesPath',
        'prepPath',
      ]) {
        expect(rules, contains('match /${pathNamed(constant)}/{'));
      }
      expect(analytics, contains("LUNCH_PLANS = '${pathNamed('plansPath')}'"));
    },
  );
}
