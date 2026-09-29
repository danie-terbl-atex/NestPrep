import '../../../shared/time/calendar_date.dart';
import '../../calendar_sync/model/synced_event.dart';
import 'birthday_occurrence.dart';
import 'event_occurrence.dart';

/// One line on a day's agenda: an event the household wrote down, a birthday
/// the calendar derived from a member's profile (birthdays ADR-0001), or an
/// event brought in from a connected calendar (calendar ADR-0003).
///
/// Sealed on purpose. A birthday carries no event and no event id, so there is
/// no code path from the calendar that could edit, delete or skip one — the
/// screen does not have to remember the rule, because the type does not offer
/// it. Editing a birthday is editing the member.
sealed class DayEntry {
  const DayEntry();

  CalendarDate get date;

  /// Stable across rebuilds, for the list key (`FE-11`).
  String get key;
}

final class EventEntry extends DayEntry {
  const EventEntry(this.occurrence);

  final EventOccurrence occurrence;

  @override
  CalendarDate get date => occurrence.date;

  @override
  String get key => occurrence.key;
}

final class BirthdayEntry extends DayEntry {
  const BirthdayEntry(this.birthday);

  final BirthdayOccurrence birthday;

  @override
  CalendarDate get date => birthday.date;

  @override
  String get key => birthday.key;
}

/// An event from somebody's Google, Outlook or Apple calendar. Like a
/// birthday it carries no household event and no event id, so nothing on the
/// calendar can edit, delete or skip it: it is changed where it came from
/// (calendar ADR-0003).
final class SyncedEntry extends DayEntry {
  const SyncedEntry(this.event, this.date);

  final SyncedEvent event;

  @override
  final CalendarDate date;

  /// A span shows on several days, so the day is part of the key.
  @override
  String get key => 'synced_${event.id}_${date.iso}';
}
