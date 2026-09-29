/// What an edit sheet that can also delete came back with. Closing the sheet is
/// null — neither of these — so a stray swipe never removes anything.
sealed class SheetOutcome<T> {
  const SheetOutcome();
}

final class SheetSaved<T> extends SheetOutcome<T> {
  const SheetSaved(this.value);

  final T value;
}

/// The person chose to remove what the sheet was editing.
final class SheetRemoved<T> extends SheetOutcome<T> {
  const SheetRemoved();
}
