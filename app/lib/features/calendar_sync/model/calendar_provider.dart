/// Where a connected calendar comes from (calendar ADR-0003). The names are
/// the stored ones, and the server's `PROVIDERS` list is the other half of
/// that contract.
///
/// `apple` is read from the calendars on this iPhone and pushed by the phone;
/// `ics` is a calendar link — any school's, club's or shared iCloud calendar.
enum CalendarProvider {
  apple,
  google,
  microsoft,
  ics;

  /// Connected through the provider's own sign-in, rather than by a link.
  bool get usesOAuth => this == google || this == microsoft;

  /// Read on the phone that linked it; no server can fetch it.
  bool get readsFromPhone => this == apple;
}
