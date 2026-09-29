import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/family_profiles/model/allergen.dart';
import 'package:nestprep/features/family_profiles/model/allergy_detail.dart';
import 'package:nestprep/features/family_profiles/model/allergy_severity.dart';
import 'package:nestprep/features/family_profiles/model/dietary_flag.dart';
import 'package:nestprep/features/family_profiles/model/family_profile.dart';
import 'package:nestprep/features/family_profiles/model/food_rules.dart';
import 'package:nestprep/features/family_profiles/model/school.dart';

import '../../../support/fake_family_profiles.dart';

/// What lunch-box plans against: the child's allergies, their diet and their
/// school's rule, gathered — never copied — from where each lives.
void main() {
  const plainSchool = School(id: 's', name: 'Greenfields');

  test('a child with nothing recorded may eat anything', () {
    final rules = FoodRules(profile: FamilyProfile.empty('m'));
    expect(rules.isUnrestricted, isTrue);
    expect(rules.isNutFree, isFalse);
    expect(rules.mustAvoid(Allergen.peanut), isFalse);
  });

  test('a nut-free school is a rule for the child, named as the school"s', () {
    final rules = FoodRules(
      profile: FamilyProfile.empty('m'),
      school: FamilyFixtures.oakwood,
    );
    expect(rules.isNutFree, isTrue);
    expect(rules.nutFreeReasons, {NutFreeReason.school});
    expect(rules.mustAvoid(Allergen.peanut), isTrue);
    expect(rules.mustAvoid(Allergen.treeNut), isTrue);
    expect(rules.mustAvoid(Allergen.milk), isFalse);
    expect(rules.isUnrestricted, isFalse);
  });

  test('the same child at a school without the rule is not nut-free', () {
    final rules = FoodRules(
      profile: FamilyProfile.empty('m'),
      school: plainSchool,
    );
    expect(rules.isNutFree, isFalse);
  });

  test('a nut allergy makes a child nut-free whatever their school says', () {
    const profile = FamilyProfile(
      id: 'm',
      allergies: {
        Allergen.treeNut: AllergyDetail(severity: AllergySeverity.mild),
      },
    );
    final rules = FoodRules(profile: profile, school: plainSchool);
    expect(rules.nutFreeReasons, {NutFreeReason.allergy});
    expect(rules.mustAvoid(Allergen.peanut), isTrue);
  });

  test('a family can choose nut-free on its own account', () {
    const profile = FamilyProfile(id: 'm', diet: {DietaryFlag.nutFree});
    expect(FoodRules(profile: profile).nutFreeReasons, {NutFreeReason.diet});
  });

  test('every reason that holds is kept, so the screen can name them all', () {
    final rules = FoodRules(
      profile: FamilyFixtures.kid.copyWith(diet: {DietaryFlag.nutFree}),
      school: FamilyFixtures.oakwood,
    );
    expect(rules.nutFreeReasons, NutFreeReason.values.toSet());
  });

  test('only the fixed allergens are machine-matched; free text is shown', () {
    final rules = FoodRules(profile: FamilyFixtures.kid);
    expect(rules.allergens, {Allergen.peanut, Allergen.milk});
    expect(rules.allergies, hasLength(3), reason: 'the kiwi is still listed');
    expect(rules.mustAvoid(Allergen.milk), isTrue);
    expect(rules.mustAvoid(Allergen.sesame), isFalse);
    expect(rules.hasSevereAllergy, isTrue);
  });

  test('likes and dislikes travel with the rules for a planner to use', () {
    final rules = FoodRules(profile: FamilyFixtures.kid);
    expect(rules.likes, ['Pasta', 'Apples']);
    expect(rules.dislikes, ['Mushrooms']);
    expect(() => rules.likes.add('x'), throwsUnsupportedError);
  });
}
