import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/documents/model/expiry_schedule.dart';
import 'package:nestprep/features/documents/model/expiry_status.dart';
import 'package:nestprep/shared/copy/vault_copy.dart';
import 'package:nestprep/shared/time/calendar_date.dart';

/// How near a document is to expiring, as the badges and "expiring soon" say
/// it (documents ADR-0005). The thresholds are the reminder offsets, so the
/// badge turns amber on the day the thirty-day reminder is raised.
void main() {
  final today = CalendarDate(2027, 6, 1);

  ExpiryUrgency urgencyIn(int days) =>
      ExpirySchedule.statusOf(today.addDays(days), today).urgency;

  test('a document with no expiry date has no status at all', () {
    final status = ExpirySchedule.statusOf(null, today);
    expect(status.urgency, ExpiryUrgency.none);
    expect(status.needsAttention, isFalse);
    expect(status.daysLeft, isNull);
  });

  test('is later, coming up, soon, today, then expired as the day nears', () {
    expect(urgencyIn(91), ExpiryUrgency.later);
    expect(urgencyIn(90), ExpiryUrgency.comingUp);
    expect(urgencyIn(31), ExpiryUrgency.comingUp);
    expect(urgencyIn(30), ExpiryUrgency.soon);
    expect(urgencyIn(1), ExpiryUrgency.soon);
    expect(urgencyIn(0), ExpiryUrgency.today);
    expect(urgencyIn(-1), ExpiryUrgency.expired);
  });

  test('"needs attention" is soon, today and expired — never coming up', () {
    expect(ExpiryUrgency.comingUp.needsAttention, isFalse);
    expect(ExpiryUrgency.later.needsAttention, isFalse);
    for (final urgent in [
      ExpiryUrgency.soon,
      ExpiryUrgency.today,
      ExpiryUrgency.expired,
    ]) {
      expect(urgent.needsAttention, isTrue, reason: urgent.name);
    }
  });

  test('counts whole days, across a month end and a leap day', () {
    final leap = CalendarDate(2028, 2, 28);
    expect(ExpirySchedule.statusOf(CalendarDate(2028, 3, 1), leap).daysLeft, 2);
  });

  test('the reminders line reads the same schedule the server sends on', () {
    expect(
      VaultCopy.remindersNote,
      'You will be reminded 90, 30 and 7 days before, and on the day.',
    );
  });
}
