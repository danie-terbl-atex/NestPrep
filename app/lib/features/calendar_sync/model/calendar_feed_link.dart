/// The household's feed link: the family week as a calendar anybody in the
/// household can subscribe to (calendar ADR-0003).
final class CalendarFeedLink {
  const CalendarFeedLink(this.url);

  /// The https address, for copying.
  final String url;

  /// The same address as a subscription, which is what makes Apple Calendar
  /// offer to subscribe rather than download it once.
  Uri get subscription =>
      Uri.parse(url.replaceFirst(RegExp('^https?'), 'webcal'));

  @override
  bool operator ==(Object other) =>
      other is CalendarFeedLink && other.url == url;

  @override
  int get hashCode => url.hashCode;
}
