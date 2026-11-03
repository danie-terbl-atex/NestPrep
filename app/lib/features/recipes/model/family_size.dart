import '../../household/model/household_view.dart';
import '../../household/model/member_role.dart';
import 'recipe.dart';

/// How many people a family meal is cooked for when nobody has said: the
/// household's family and children (recipes ADR-0003 §5). A helper or a carer
/// is a member too, but is not who the dinner is counted for.
int familySizeOf(HouseholdView view) => view.members
    .where((member) => member.role.isFamily || member.role == MemberRole.kid)
    .length;

/// A family meal starts at the family's size; anything else — a lunch-box
/// treat, a tray of rusks — at what the recipe makes.
int startingPeopleFor(Recipe recipe, int familySize) =>
    recipe.firstMeal != null && familySize > 0 ? familySize : recipe.servings;
