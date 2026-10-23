/// The steps of *Plan my week* (lunch-box ADR-0012), each confirmed before
/// the next: the brief, the ideas, the shop, the week, and done. Ready-made
/// boxes are *Fill the week*'s since lunch-box ADR-0020.
enum PlanWeekStep {
  brief,
  ideas,
  store,
  week,
  done;

  /// Where *Back* goes: one step, except that the shop and the week are one
  /// run from the ideas, so both go back to them.
  PlanWeekStep get previous => switch (this) {
    brief || ideas => brief,
    store || week || done => ideas,
  };
}
