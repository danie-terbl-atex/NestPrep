import '../../../design/nest_kit.dart';
import '../../household/model/household_view.dart';
import '../model/day_entry.dart';

/// Whose colours one line of a day is drawn in, in the order it names them —
/// none for an event that is nobody's in particular. The month grid's dots
/// and Today's rows read the same answer (`ENG-01`).
List<MemberColor> entryColors(DayEntry entry, HouseholdView view) =>
    switch (entry) {
      EventEntry(:final occurrence) => [
        for (final id in occurrence.event.memberIds)
          ?view.memberById(id)?.color,
      ],
      BirthdayEntry(:final birthday) => [birthday.member.color],
      SyncedEntry(:final event) => [?view.memberById(event.memberId)?.color],
    };
