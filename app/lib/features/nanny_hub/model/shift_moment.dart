/// The five parts of a shift a checklist can be for, in the order a shift
/// meets them (nanny-hub ADR-0001). The names are the checklist documents'
/// ids, and `nanny_hub.rules` and `endNannyShift` spell them the same way.
enum ShiftMoment {
  arrival,
  afterSchool,
  dinner,
  bedtime,
  beforeLeaving;

  static ShiftMoment? fromName(String name) =>
      values.where((moment) => moment.name == name).firstOrNull;
}
