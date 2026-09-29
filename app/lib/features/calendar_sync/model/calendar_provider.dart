/// Where a connected calendar comes from (calendar ADR-0003). The names are
/// the stored ones, and the server's `PROVIDERS` list is the other half of
/// that contract.
///
/// `ics` is a calendar link — Apple's way in, and any school's or club's
/// published calendar.
enum CalendarProvider {
  google,
  microsoft,
  ics;

  /// Connected through the provider's own sign-in, rather than by a link.
  bool get usesOAuth => this != ics;
}
