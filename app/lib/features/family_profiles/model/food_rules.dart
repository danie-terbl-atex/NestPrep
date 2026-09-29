import 'package:flutter/foundation.dart';

import 'allergen.dart';
import 'allergy.dart';
import 'dietary_flag.dart';
import 'family_profile.dart';
import 'school.dart';

/// Why somebody must not be given nuts. More than one can hold at once, and a
/// screen says which, because "nut-free — school rule" and "nut-free —
/// allergy" ask different things of the person packing the lunch.
enum NutFreeReason { allergy, diet, school }

/// Everything that limits what one person may be given to eat, gathered from
/// their profile and their school — the read lunch-box plans against and a
/// carer's card shows (family-profiles ADR-0001).
///
/// Derived, never stored: allergies have one home, the profile, and the
/// school's rule has one home, the school. Nothing here is a copy that could
/// disagree with either.
@immutable
class FoodRules {
  FoodRules({required FamilyProfile profile, this.school})
    : allergies = List.unmodifiable(profile.allAllergies),
      diet = Set.unmodifiable(profile.diet),
      likes = List.unmodifiable(profile.likes),
      dislikes = List.unmodifiable(profile.dislikes);

  /// Most dangerous first.
  final List<Allergy> allergies;
  final Set<DietaryFlag> diet;
  final List<String> likes;
  final List<String> dislikes;

  /// The school whose rules apply, if the person has one.
  final School? school;

  /// The fixed allergens this person reacts to — the set a lunch box is
  /// checked against. Free-text allergies are in [allergies] and cannot be
  /// matched by a machine.
  Set<Allergen> get allergens => {
    for (final allergy in allergies) ?allergy.allergen,
  };

  Set<NutFreeReason> get nutFreeReasons => {
    if (allergens.any((allergen) => allergen.isNut)) NutFreeReason.allergy,
    if (diet.contains(DietaryFlag.nutFree)) NutFreeReason.diet,
    if (school?.nutFree ?? false) NutFreeReason.school,
  };

  bool get isNutFree => nutFreeReasons.isNotEmpty;

  /// Whether food containing [allergen] must stay away from this person —
  /// because they are allergic to it, or because nuts are ruled out for them
  /// by their diet or their school.
  bool mustAvoid(Allergen allergen) =>
      allergens.contains(allergen) || (allergen.isNut && isNutFree);

  bool get hasSevereAllergy =>
      allergies.any((allergy) => allergy.severity.isSevere);

  /// Nothing restricts what they eat.
  bool get isUnrestricted => allergies.isEmpty && diet.isEmpty && !isNutFree;
}
