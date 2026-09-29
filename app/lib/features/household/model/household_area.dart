import 'access_level.dart';

/// Every part of a household a grant can open or close (household ADR-0003).
///
/// **These keys are a contract.** Home-care, nanny-hub, family-profiles,
/// lunch-box and documents gate on them; `firestore.rules`, `storage.rules` and
/// `functions/src/household/access.ts` spell them the same way, and
/// `access_contract_test.dart` reads that file to prove it. Rename one here and
/// a helper's grant silently stops matching.
enum HouseholdArea {
  calendar('calendar', _noOwn),
  groceries('groceries', _noOwn),
  todos('todos', _withOwn),
  meals('meals', _noOwn),
  documents('documents', _noOwn),
  lunch('lunch', _withOwn),
  familyProfiles('familyProfiles', _withOwn),
  medical('medical', _withOwn),
  homeCare('homeCare', _withOwn),
  nannyHub('nannyHub', _noOwn);

  const HouseholdArea(this.key, this.levels);

  /// The stored name, in the grant map and in the rules.
  final String key;

  /// The levels this area accepts. `own` only where "theirs" means something:
  /// a task's assignees, a child's lunches, a profile's own member, a
  /// helper's jobs.
  final List<AccessLevel> levels;

  static HouseholdArea? fromKey(String key) =>
      HouseholdArea.values.where((area) => area.key == key).firstOrNull;

  /// A level this area does not accept means `none` — never more.
  AccessLevel accept(AccessLevel level) =>
      levels.contains(level) ? level : AccessLevel.none;
}

const _noOwn = [AccessLevel.none, AccessLevel.view, AccessLevel.edit];
const _withOwn = [
  AccessLevel.none,
  AccessLevel.own,
  AccessLevel.view,
  AccessLevel.edit,
];
