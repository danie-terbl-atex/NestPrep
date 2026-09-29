import 'legal_block.dart';
import 'legal_document.dart';
import 'legal_inline_parser.dart';
import 'legal_span.dart';

final _frontMatterLine = RegExp(r'^(\w+):\s*(.*)$');
final _isoDate = RegExp(r'^\d{4}-\d{2}-\d{2}$');
final _unsupported = RegExp(r'^(#|\||>|\d+\. |\s*<)');

/// Parses a legal document from the small Markdown subset the documents are
/// written in: front matter (`title`, `version`, `updated`), `##` and `###`
/// headings, paragraphs, single-level `- ` bullets, and the inline forms
/// `parseLegalInline` reads.
///
/// Strict on purpose. Anything outside the subset is a [FormatException]
/// rather than something rendered wrongly on a phone, and the test that parses
/// the shipped documents turns it into a failing build.
LegalDocument parseLegalDocument(String source) {
  final lines = source.replaceAll('\r\n', '\n').split('\n');
  final (fields, bodyStart) = _frontMatter(lines);
  return LegalDocument(
    title: _required(fields, 'title'),
    version: _version(_required(fields, 'version')),
    updated: _date(_required(fields, 'updated')),
    blocks: _LegalBodyReader().read(lines.skip(bodyStart)),
  );
}

(Map<String, String>, int) _frontMatter(List<String> lines) {
  if (lines.first.trim() != '---') {
    throw const FormatException('a legal document starts with front matter');
  }
  final fields = <String, String>{};
  for (var index = 1; index < lines.length; index++) {
    final line = lines[index].trim();
    if (line == '---') return (fields, index + 1);
    final match = _frontMatterLine.firstMatch(line);
    if (match == null) throw FormatException('bad front matter', line);
    fields[match.group(1)!] = match.group(2)!.trim();
  }
  throw const FormatException('front matter is never closed');
}

String _required(Map<String, String> fields, String key) {
  final value = fields[key];
  if (value == null || value.isEmpty) {
    throw FormatException('front matter has no $key');
  }
  return value;
}

int _version(String value) {
  final version = int.tryParse(value);
  if (version == null || version < 1) {
    throw FormatException('version must be a whole number from 1', value);
  }
  return version;
}

String _date(String value) {
  if (!_isoDate.hasMatch(value)) {
    throw FormatException('updated must be YYYY-MM-DD', value);
  }
  return value;
}

/// Walks the body line by line, holding the paragraph or bullet list it is
/// in the middle of until a blank line, a heading or the other kind ends it.
final class _LegalBodyReader {
  final _blocks = <LegalBlock>[];
  final _paragraph = <String>[];
  final _bullets = <List<String>>[];

  List<LegalBlock> read(Iterable<String> lines) {
    lines.forEach(_readLine);
    _flush();
    return List.unmodifiable(_blocks);
  }

  void _readLine(String raw) {
    final line = raw.trimRight();
    if (line.trim().isEmpty) return _flush();
    if (line.startsWith('## ') || line.startsWith('### ')) {
      _flush();
      final level = line.startsWith('### ') ? 3 : 2;
      _blocks.add(
        LegalHeading(
          level: level,
          spans: parseLegalInline(line.substring(level + 1).trim()),
        ),
      );
      return;
    }
    if (_unsupported.hasMatch(line)) {
      throw FormatException('outside the legal Markdown subset', line);
    }
    if (line.startsWith('- ')) {
      _flushParagraph();
      _bullets.add([line.substring(2).trim()]);
      return;
    }
    // An indented line under a bullet is that bullet, wrapped.
    if (_bullets.isNotEmpty && raw.startsWith(' ')) {
      _bullets.last.add(line.trim());
      return;
    }
    _flushBullets();
    _paragraph.add(line.trim());
  }

  void _flush() {
    _flushParagraph();
    _flushBullets();
  }

  void _flushParagraph() {
    if (_paragraph.isEmpty) return;
    _blocks.add(LegalParagraph(_spans(_paragraph)));
    _paragraph.clear();
  }

  void _flushBullets() {
    if (_bullets.isEmpty) return;
    _blocks.add(LegalBullets([for (final item in _bullets) _spans(item)]));
    _bullets.clear();
  }

  List<LegalSpan> _spans(List<String> lines) =>
      parseLegalInline(lines.join(' '));
}
