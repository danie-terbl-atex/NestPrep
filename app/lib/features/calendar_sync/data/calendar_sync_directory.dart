import '../model/calendar_feed_link.dart';
import '../model/calendar_provider.dart';
import '../model/provider_availability.dart';

/// The calendar sync callables (calendar ADR-0003) — everything here is a
/// Function, because it holds a credential or talks to a provider. Each
/// refusal arrives as a `CalendarSyncFailure` or `HouseholdFailure`, never as
/// an SDK error (`BE-04`).
abstract interface class CalendarSyncDirectory {
  Future<ProviderAvailability> availableProviders(String householdId);

  /// The provider's consent page to open in the browser. The rest of the
  /// connection happens between the browser and a Function.
  Future<Uri> startConnection(String householdId, CalendarProvider provider);

  Future<void> connectLink(String householdId, String url);

  Future<void> syncNow(String householdId, String connectionId);

  Future<void> disconnect(String householdId, String connectionId);

  /// The household's feed link, made the first time anybody asks.
  Future<CalendarFeedLink> shareFeed(String householdId);

  /// A new feed link; the old one stops working. An admin's call.
  Future<CalendarFeedLink> resetFeed(String householdId);
}
