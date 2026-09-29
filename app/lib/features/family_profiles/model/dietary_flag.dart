/// The ways a person eats that a lunch or a carer has to respect, from a fixed
/// set so lunch-box can apply them and the rules can check them with `hasOnly`
/// (family-profiles ADR-0001). Nut-free is here as a choice a family makes on
/// its own account; a school's nut-free rule lives on the school.
enum DietaryFlag {
  nutFree,
  vegetarian,
  vegan,
  halal,
  kosher,
  noPork,
  glutenFree,
  dairyFree;

  static DietaryFlag? fromCode(String code) =>
      values.where((flag) => flag.name == code).firstOrNull;
}
