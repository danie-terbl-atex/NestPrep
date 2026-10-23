import '../../lunch_box/model/lunch_slot.dart';

/// The school days *Plan my week* may plan a treat on (lunch-box ADR-0025),
/// as ISO weekdays — Monday 1 to Friday 5. Empty plans no treat. The server
/// holds the same rule (`openCompartments`) and has the last word; this is
/// the phone's copy so the week it shows matches what it will be sent.
///
/// Only *Plan my week* reads these: auto-fill, *Fill the week* and kid picks
/// keep ADR-0003's Friday (`LunchSlot.isAutoFilledOn`).
abstract final class TreatDays {
  /// Monday to Friday, in the order a week is read.
  static const schoolDays = [
    DateTime.monday,
    DateTime.tuesday,
    DateTime.wednesday,
    DateTime.thursday,
    DateTime.friday,
  ];

  /// ADR-0003's Friday: what a household that has not chosen gets, here and
  /// on the server.
  static const fridayOnly = {DateTime.friday};

  /// The school days in [days], whatever else it holds.
  static Set<int> schoolDaysIn(Iterable<Object?> days) => {
    for (final day in schoolDays)
      if (days.contains(day)) day,
  };

  /// [days] as the wire and the phone's store carry them: Monday first.
  static List<int> inOrder(Set<int> days) => [
    for (final day in schoolDays)
      if (days.contains(day)) day,
  ];
}

/// Whether *Plan my week* may fill this compartment on [isoWeekday], given
/// the household's [treatDays]: every compartment but the treat on every
/// school day, the treat only on a treat day (lunch-box ADR-0025).
extension TreatDaysOfSlot on LunchSlot {
  bool isPlannedOn(int isoWeekday, Set<int> treatDays) =>
      this != LunchSlot.treat || treatDays.contains(isoWeekday);
}
