/// What a cleaning product *is*, chemically — the key the safety catalogue
/// is read by (home-care ADR-0002). A household names its own products; the
/// kind is chosen from this list, so the warnings do not depend on anybody
/// knowing what is in the blue bottle.
///
/// Stored by name; the rules partial lists the same names, and a test reads
/// both.
enum ProductKind {
  bleach,
  ammonia,
  acidic,
  alcohol,
  peroxide,
  ovenCleaner,
  drainCleaner,
  disinfectant,
  allPurpose,
  dishSoap,
  bicarbonate,
  polish,
  floorCleaner,
  other,
}
