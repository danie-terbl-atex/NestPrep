import 'calendar_provider.dart';

/// Which calendars this deployment can connect (calendar ADR-0003). A calendar
/// link needs no credentials and is always available; Google and Outlook need
/// OAuth clients that may not exist yet, and say so before anybody taps.
final class ProviderAvailability {
  const ProviderAvailability({required this.google, required this.microsoft});

  final bool google;
  final bool microsoft;

  bool isAvailable(CalendarProvider provider) => switch (provider) {
    CalendarProvider.google => google,
    CalendarProvider.microsoft => microsoft,
    CalendarProvider.ics => true,
  };

  @override
  bool operator ==(Object other) =>
      other is ProviderAvailability &&
      other.google == google &&
      other.microsoft == microsoft;

  @override
  int get hashCode => Object.hash(google, microsoft);
}
