/// The steps of *Fill the week* (lunch-box ADR-0020), each confirmed before
/// the next: choose boxes, review the whole week, and done.
enum FillWeekStep {
  boxes,
  review,
  done;

  /// Where *Back* goes: the review goes back to the boxes; the first step
  /// leaves the flow, which the screen does.
  FillWeekStep get previous => switch (this) {
    boxes || review => boxes,
    done => review,
  };
}
