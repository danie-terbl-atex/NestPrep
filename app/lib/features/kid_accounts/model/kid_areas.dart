import '../../household/model/household_area.dart';
import '../../household/model/household_permissions.dart';

/// What a kid device's screen shows, read off the grant its kid profile holds
/// (accounts ADR-0004): the same answer the rules give, so the device never
/// opens a read the server would refuse.
///
/// A parent narrows or widens it in the access editor, and the kid's screen
/// follows on the next emission of the profile.
final class KidAreas {
  const KidAreas({
    required this.chores,
    required this.canTick,
    required this.food,
    this.lunch = false,
  });

  factory KidAreas.of(HouseholdPermissions permissions) => KidAreas(
    chores: permissions.canUse(HouseholdArea.todos),
    canTick:
        permissions.canEdit(HouseholdArea.todos) ||
        permissions.hasOwnOnly(HouseholdArea.todos),
    food: permissions.canView(HouseholdArea.meals),
    lunch: permissions.canUse(HouseholdArea.lunch),
  );

  /// Nothing at all — a profile with no grant, or one that is no longer a kid.
  static const nothing = KidAreas(chores: false, canTick: false, food: false);

  /// Their jobs are shown — `own`, `view` or `edit` on to-dos.
  final bool chores;

  /// They may tick a job off — `own` or `edit`; `view` only looks.
  final bool canTick;

  /// Today's food is shown — `view` or `edit` on meals.
  final bool food;

  /// Their own lunch box today is shown — anything but `none` on lunch; the
  /// kid defaults hold `own` (lunch-box ADR-0004).
  final bool lunch;

  bool get showsAnything => chores || food || lunch;

  @override
  bool operator ==(Object other) =>
      other is KidAreas &&
      other.chores == chores &&
      other.canTick == canTick &&
      other.food == food &&
      other.lunch == lunch;

  @override
  int get hashCode => Object.hash(chores, canTick, food, lunch);
}
