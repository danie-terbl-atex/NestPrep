/// The allergens a household records as themselves rather than as free text
/// (family-profiles ADR-0001): the ones South Africa's labelling regulations
/// name, plus sesame. Being a fixed list is what lets lunch-box match one
/// against a box, and lets Security Rules read a child's allergens with one
/// `get`. Anything else is an `OtherAllergy`.
///
/// The stored code is the enum's name, and `firestore.rules` lists the same
/// nine — `family_vocabulary_matches_the_rules_test.dart` holds them together.
enum Allergen {
  peanut,
  treeNut,
  milk,
  egg,
  wheat,
  soy,
  fish,
  shellfish,
  sesame;

  /// The allergen a stored code names, or null for one this build does not
  /// know — a later build may add to the list (`BE-10`).
  static Allergen? fromCode(String code) =>
      values.where((allergen) => allergen.name == code).firstOrNull;

  /// A stored list of codes from system data (recipes, ready-made boxes),
  /// or null when any entry is not a code this build knows: something whose
  /// contents cannot be checked is never treated as safe.
  static Set<Allergen>? parseCodes(Object? value) {
    if (value is! List<Object?>) return null;
    final known = [
      for (final code in value)
        if (code is String) ?fromCode(code),
    ];
    return known.length == value.length ? known.toSet() : null;
  }

  /// A nut allergy makes a person nut-free whatever else is recorded.
  bool get isNut => this == peanut || this == treeNut;
}
