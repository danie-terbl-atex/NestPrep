/// One document read from a collection the app does not write — system data
/// a later backend may change the shape of (`BE-10`). Either the typed value,
/// or why it was left out, for the log (`ENG-09`, `ENG-22`): a document this
/// build cannot read is dropped with its reason, never a crash and never a
/// guess.
sealed class ParsedDocument<T> {
  const ParsedDocument();
}

final class ValidDocument<T> extends ParsedDocument<T> {
  const ValidDocument(this.value, {this.dropped = const []});

  final T value;

  /// Parts of the document left out because this build cannot read them —
  /// one entry each, said as the kind of field, never its key or value.
  final List<String> dropped;
}

final class RejectedDocument<T> extends ParsedDocument<T> {
  const RejectedDocument(this.reason);

  /// The field that was missing or wrong — never a value from it.
  final String reason;
}
