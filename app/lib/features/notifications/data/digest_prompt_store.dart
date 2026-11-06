import '../../../shared/time/calendar_date.dart';

/// The household day this device last offered a person their digest on
/// (notifications ADR-0005). On the device only, never synced.
abstract interface class DigestPromptStore {
  Future<CalendarDate?> lastOffered(String householdId, String memberId);

  Future<void> markOffered(
    String householdId,
    String memberId,
    CalendarDate day,
  );
}
