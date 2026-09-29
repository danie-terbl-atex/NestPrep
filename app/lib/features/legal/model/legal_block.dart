import 'legal_span.dart';

/// One block of a legal document, in reading order.
sealed class LegalBlock {
  const LegalBlock();
}

/// A section (`##`, level 2) or a sub-section (`###`, level 3).
final class LegalHeading extends LegalBlock {
  const LegalHeading({required this.level, required this.spans});

  final int level;
  final List<LegalSpan> spans;
}

final class LegalParagraph extends LegalBlock {
  const LegalParagraph(this.spans);

  final List<LegalSpan> spans;
}

/// A run of `- ` bullets. One level only: the documents are written for a
/// phone, and a nested list does not survive 200% text on one.
final class LegalBullets extends LegalBlock {
  const LegalBullets(this.items);

  final List<List<LegalSpan>> items;
}
