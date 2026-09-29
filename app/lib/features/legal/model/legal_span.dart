/// One run of inline text in a legal document — plain, a link, or a
/// placeholder the lawyer has still to fill (`[legal entity name]`).
///
/// Bold is a property of a run rather than a kind of its own, because a
/// placeholder or a link can sit inside bold and still has to read as what it
/// is.
sealed class LegalSpan {
  const LegalSpan({required this.text, this.isBold = false});

  final String text;
  final bool isBold;
}

final class LegalText extends LegalSpan {
  const LegalText(String text, {super.isBold}) : super(text: text);
}

/// A link a person can follow out of the app: `http`, `https` or `mailto`
/// only — the parser refuses anything else, so a document can never open an
/// intent or a file on the phone.
final class LegalLink extends LegalSpan {
  const LegalLink(String text, this.target, {super.isBold}) : super(text: text);

  final Uri target;
}

/// A gap in the draft, shown as a gap. It is never quietly rendered as
/// ordinary text, so a draft that still has one cannot pass for final.
final class LegalPlaceholder extends LegalSpan {
  const LegalPlaceholder(String text, {super.isBold}) : super(text: text);
}
