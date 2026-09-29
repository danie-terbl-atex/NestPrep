/// Where a statement in the safety catalogue comes from (home-care ADR-0002).
/// The catalogue is a summary of these, not advice of NestPrep's own, and the
/// "Where this comes from" sheet names each one.
///
/// The titles and publishers are in `HomeCareCopy`, because they are read by
/// people; this is the key.
enum SafetySource {
  /// US Centers for Disease Control and Prevention — cleaning and
  /// disinfecting with bleach: bleach only with water, never with ammonia or
  /// another cleanser, gloves and fresh air.
  cdcBleach,

  /// Washington State Department of Health — why bleach is never mixed with
  /// ammonia, acids or rubbing alcohol, and what each makes.
  washingtonHealth,

  /// National Capital Poison Center (poison.org) — mixing cleaning products,
  /// hydrogen peroxide with vinegar, and drain cleaners.
  poisonControl,

  /// South Africa's Poisons Information Helpline, for an accident.
  poisonsHelpline,
}
