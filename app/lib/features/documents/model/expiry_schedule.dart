import '../../../shared/time/calendar_date.dart';
import 'expiry_status.dart';

/// When a document's expiry matters, on the phone (documents ADR-0005).
///
/// **The offsets are a contract with the server.** The daily sweep in
/// `functions/src/documents/expiry_schedule.ts` raises a reminder at each of
/// them, and `expiry_schedule_contract_test.dart` reads that file and fails if
/// the two lists drift apart — so the badge a person sees and the reminder
/// they are sent always agree about what "soon" is.
abstract final class ExpirySchedule {
  /// Days before expiry that a reminder is raised; 0 is the day itself.
  static const reminderDaysBefore = <int>[90, 30, 7, 0];

  /// Inside this many days a document is *soon* — the second reminder.
  static int get soonWithinDays => reminderDaysBefore[1];

  /// Inside this many days it is *coming up* — the first reminder.
  static int get comingUpWithinDays => reminderDaysBefore.first;

  /// How [expiresOn] stands on [today], both days in the household's zone.
  static ExpiryStatus statusOf(CalendarDate? expiresOn, CalendarDate today) {
    if (expiresOn == null) return const ExpiryStatus.none();
    final daysLeft = today.daysUntil(expiresOn);
    final urgency = switch (daysLeft) {
      < 0 => ExpiryUrgency.expired,
      0 => ExpiryUrgency.today,
      _ when daysLeft <= soonWithinDays => ExpiryUrgency.soon,
      _ when daysLeft <= comingUpWithinDays => ExpiryUrgency.comingUp,
      _ => ExpiryUrgency.later,
    };
    return ExpiryStatus(urgency: urgency, daysLeft: daysLeft, date: expiresOn);
  }
}
