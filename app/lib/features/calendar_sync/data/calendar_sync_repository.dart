import '../../../shared/time/calendar_date.dart';
import '../model/calendar_connection.dart';
import '../model/calendar_feed_link.dart';
import '../model/synced_event.dart';

/// What calendar sync reads from Firestore (calendar ADR-0003). All three are
/// read-only here: a Function writes every one of them.
abstract interface class CalendarSyncRepository {
  Stream<List<CalendarConnection>> watchConnections(String householdId);

  /// Imported occurrences starting within the window, reaching back
  /// [spanReachDays] so a half-term that began last week still shows (`BE-08`).
  Stream<List<SyncedEvent>> watchSyncedEvents(
    String householdId, {
    required CalendarDate from,
    required CalendarDate to,
  });

  /// The household's feed link, or null before anybody has asked for one.
  Stream<CalendarFeedLink?> watchFeedLink(String householdId);

  /// A household connects a handful of calendars, never dozens.
  static const connectionLimit = 30;

  /// How far back an all-day span may start and still reach into a window.
  static const spanReachDays = 14;
}
