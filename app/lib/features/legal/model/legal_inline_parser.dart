import 'legal_span.dart';

final _inline = RegExp(
  r'\*\*(.+?)\*\*' // bold
  r'|\[([^\]]+)\]\(([^)\s]+)\)' // [text](target)
  r'|\[([^\]]+)\]', // [placeholder]
);

const _followableSchemes = {'http', 'https', 'mailto'};

/// Reads one line of inline Markdown — `**bold**`, `[text](url)` and a bare
/// `[placeholder]` — into runs. Anything else is text, exactly as written.
///
/// A link to anything but the web or an email address is refused rather than
/// rendered: it is a mistake in the document, and the test that parses the
/// shipped documents is where it should be caught (`ENG-09`).
List<LegalSpan> parseLegalInline(String line, {bool isBold = false}) {
  final spans = <LegalSpan>[];
  var cursor = 0;
  for (final match in _inline.allMatches(line)) {
    if (match.start > cursor) {
      spans.add(LegalText(line.substring(cursor, match.start), isBold: isBold));
    }
    spans.addAll(_spansOf(match, isBold: isBold));
    cursor = match.end;
  }
  if (cursor < line.length) {
    spans.add(LegalText(line.substring(cursor), isBold: isBold));
  }
  return spans;
}

List<LegalSpan> _spansOf(RegExpMatch match, {required bool isBold}) {
  final bold = match.group(1);
  if (bold != null) {
    if (isBold) throw FormatException('bold inside bold', bold);
    return parseLegalInline(bold, isBold: true);
  }
  final linkText = match.group(2);
  final target = match.group(3);
  if (linkText != null && target != null) {
    return [LegalLink(linkText, _followable(target), isBold: isBold)];
  }
  return [LegalPlaceholder(match.group(4)!, isBold: isBold)];
}

Uri _followable(String target) {
  final uri = Uri.tryParse(target);
  if (uri == null || !_followableSchemes.contains(uri.scheme)) {
    throw FormatException('a link must be http, https or mailto', target);
  }
  return uri;
}
