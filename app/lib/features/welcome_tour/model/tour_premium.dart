/// What a tour callout says about premium (welcome-tour ADR-0002).
enum TourPremium {
  /// Not premium's.
  none,

  /// Premium's, and the household has it: the callout says it is theirs.
  included,

  /// Premium's, and the household has not bought it: the callout carries the
  /// tag, rather than the tool being hidden.
  offered,
}
