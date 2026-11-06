import '../model/apple_calendar.dart';

/// What this phone linked, per account and household. It lives on the phone
/// because the calendars it names exist only here.
abstract interface class AppleCalendarLinkStore {
  Future<AppleCalendarLink?> read(String uid, String householdId);

  Future<void> write(String uid, String householdId, AppleCalendarLink link);

  Future<void> clear(String uid, String householdId);
}
