import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/family_profiles/data/family_profile_repository.dart';
import 'package:nestprep/features/family_profiles/model/allergen.dart';
import 'package:nestprep/features/family_profiles/model/allergy_severity.dart';
import 'package:nestprep/features/family_profiles/model/dietary_flag.dart';
import 'package:nestprep/features/family_profiles/model/family_profile.dart';
import 'package:nestprep/features/family_profiles/model/member_health.dart';
import 'package:nestprep/features/family_profiles/state/family_edits.dart';

/// The allergen and diet vocabularies, the limits, and the collection names
/// are written down three times: in the app, in `firestore.rules`, and in the
/// Function that deletes a removed member's details. Written down twice is a
/// contract, and a contract between two languages needs a test that reads both
/// (the vault lesson of that name). Add an allergen to the app and not the
/// rules and every save of it is refused; add it to the rules and not the app
/// and it is read as free text.
void main() {
  final rules = File('../firestore.rules').readAsStringSync();
  final removal = File('../functions/src/family_profiles/member_details.ts')
      .readAsStringSync();

  // Read as text rather than imported: the Firestore repository is kept out
  // of the widget tests' reach on purpose (`coverage_is_honest_test.dart`).
  final repository = File(
    'lib/features/family_profiles/data/firestore_family_profile_repository.dart',
  ).readAsStringSync();
  String pathNamed(String constant) =>
      RegExp("static const $constant = '(\\w+)';")
          .firstMatch(repository)!
          .group(1)!;

  /// The quoted words in the first `hasOnly([...])` after [anchor].
  Set<String> listAfter(String anchor) {
    final start = rules.indexOf(anchor);
    expect(start, isNot(-1), reason: 'the rules no longer say "$anchor"');
    final list = RegExp(r'hasOnly\(\s*\[([^\]]*)\]')
        .firstMatch(rules.substring(start))!
        .group(1)!;
    return {
      for (final match in RegExp("'(\\w+)'").allMatches(list)) match.group(1)!,
    };
  }

  test('the rules accept exactly the allergens the app knows', () {
    expect(listAfter('function isAllergyMap'), {
      for (final allergen in Allergen.values) allergen.name,
    });
  });

  test('and check the value of every one of them by name', () {
    for (final allergen in Allergen.values) {
      expect(
        rules,
        contains("isAllergyAt(allergies, '${allergen.name}')"),
        reason: 'rules cannot loop, so each allergen is checked by name',
      );
    }
  });

  test('the rules accept exactly the severities the app writes', () {
    final severities = RegExp(r"get\('severity', ''\) in \[([^\]]*)\]")
        .firstMatch(rules)!
        .group(1)!;
    expect(
      {for (final m in RegExp("'(\\w+)'").allMatches(severities)) m.group(1)},
      {for (final severity in AllergySeverity.values) severity.name},
    );
  });

  test('the rules accept exactly the diets the app knows', () {
    expect(listAfter("data.get('diet', []).hasOnly"), {
      for (final flag in DietaryFlag.values) flag.name,
    });
  });

  test('the limits the app stops at are the ones the rules refuse past', () {
    expect(
      rules,
      contains('value.size() <= ${FamilyEdits.listLimit}'),
      reason: 'likes and dislikes',
    );
    expect(
      rules,
      contains(
        "data.get('otherAllergies', {}).size() <= "
        '${FamilyProfile.otherAllergyLimit}',
      ),
    );
    expect(
      rules,
      contains(
        "data.get('medications', {}).size() <= "
        '${MemberHealth.medicationLimit}',
      ),
    );
  });

  test('the app, the rules and removeMember name the same collections', () {
    final profiles = pathNamed('profilesPath');
    final health = pathNamed('healthPath');
    for (final path in [profiles, health, pathNamed('schoolsPath')]) {
      expect(rules, contains('match /$path/{'));
    }
    expect(removal, contains("FAMILY_PROFILES = '$profiles'"));
    expect(removal, contains("MEMBER_HEALTH = '$health'"));
  });

  test('one profile per member means the member limit bounds profiles too', () {
    expect(FamilyProfileRepository.profileLimit, greaterThanOrEqualTo(50));
  });
}
