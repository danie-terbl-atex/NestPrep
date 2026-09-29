/// How serious an allergy is. Declared mildest first; every list of allergies
/// is shown most dangerous first (family-profiles ADR-0001).
enum AllergySeverity {
  mild,
  moderate,
  severe;

  /// A stored severity this build does not recognise reads as **severe**.
  /// Reading it as mild, or dropping it, would quietly make an allergy less
  /// serious than a parent said it was; over-warning is the safe mistake.
  static AllergySeverity fromCode(Object? code) =>
      values.where((severity) => severity.name == code).firstOrNull ??
      AllergySeverity.severe;

  bool get isSevere => this == severe;
}
