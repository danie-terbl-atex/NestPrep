/// How much of one area a kid, helper or carer may use (household ADR-0003).
/// Declared from least to most, so a comparison reads as "at least".
enum AccessLevel {
  /// The area does not exist for them.
  none,

  /// Only what is theirs: assigned to, or about, their own profile.
  own,

  /// Everything in the area, read-only.
  view,

  /// What family does: read everything, add, change, tick.
  edit;

  /// Reads a stored level. Anything unrecognised is `none`, so a bad value
  /// narrows what the app shows rather than widening it.
  static AccessLevel fromName(Object? name) => AccessLevel.values.firstWhere(
    (level) => level.name == name,
    orElse: () => AccessLevel.none,
  );

  bool get seesEverything =>
      this == AccessLevel.view || this == AccessLevel.edit;

  bool get isAnything => this != AccessLevel.none;
}
