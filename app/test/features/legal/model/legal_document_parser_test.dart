import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/legal/model/legal_block.dart';
import 'package:nestprep/features/legal/model/legal_document_parser.dart';
import 'package:nestprep/features/legal/model/legal_inline_parser.dart';
import 'package:nestprep/features/legal/model/legal_span.dart';

/// The legal Markdown subset (accounts ADR-0005): what it reads, and that
/// it refuses everything else rather than rendering it wrongly on a phone.
void main() {
  const frontMatter =
      '---\ntitle: Privacy Policy\nversion: 3\n'
      'updated: 2026-09-29\n---\n';

  group('front matter', () {
    test('gives the title, the version and the date', () {
      final document = parseLegalDocument('${frontMatter}Hello.');
      expect(document.title, 'Privacy Policy');
      expect(document.version, 3);
      expect(document.updated, '2026-09-29');
    });

    test('is required, and every field in it', () {
      expect(
        () => parseLegalDocument('No front matter.'),
        throwsFormatException,
      );
      expect(
        () => parseLegalDocument('---\ntitle: X\nversion: 1\n---\n'),
        throwsFormatException,
        reason: 'no updated date',
      );
      expect(
        () => parseLegalDocument('---\ntitle: X\nversion: 1\nupdated: 2026'),
        throwsFormatException,
        reason: 'never closed',
      );
    });

    test('refuses a version that is not a whole number from 1', () {
      for (final version in ['0', 'one', '1.5', '-2']) {
        expect(
          () => parseLegalDocument(
            '---\ntitle: X\nversion: $version\nupdated: 2026-09-29\n---\n',
          ),
          throwsFormatException,
          reason: version,
        );
      }
    });

    test('refuses a date that is not YYYY-MM-DD', () {
      expect(
        () => parseLegalDocument(
          '---\ntitle: X\nversion: 1\nupdated: 29 September\n---\n',
        ),
        throwsFormatException,
      );
    });
  });

  group('blocks', () {
    test('headings at two levels, paragraphs and bullets, in order', () {
      final blocks = parseLegalDocument(
        '$frontMatter'
        '## 1. Who we are\n'
        'We are a company\n'
        'on two lines.\n'
        '\n'
        '### Children\n'
        '- one\n'
        '- two\n'
        '  wrapped\n'
        'After the list.\n',
      ).blocks;

      expect(blocks, hasLength(5));
      expect((blocks[0] as LegalHeading).level, 2);
      expect(_text((blocks[0] as LegalHeading).spans), '1. Who we are');
      expect(
        _text((blocks[1] as LegalParagraph).spans),
        'We are a company on two lines.',
        reason: 'a wrapped paragraph is one paragraph',
      );
      expect((blocks[2] as LegalHeading).level, 3);
      final bullets = blocks[3] as LegalBullets;
      expect(bullets.items.map(_text), ['one', 'two wrapped']);
      expect(_text((blocks[4] as LegalParagraph).spans), 'After the list.');
    });

    test('refuses what the subset does not have', () {
      for (final line in [
        '# A top heading',
        '#### Too deep',
        '| a | table |',
        '> a quote',
        '1. a numbered list',
        '<b>html</b>',
      ]) {
        expect(
          () => parseLegalDocument('$frontMatter$line\n'),
          throwsFormatException,
          reason: line,
        );
      }
    });

    test('an empty body is a document with no blocks', () {
      expect(parseLegalDocument(frontMatter).blocks, isEmpty);
    });
  });

  group('inline', () {
    test('bold, links and placeholders, with the text between', () {
      final spans = parseLegalInline(
        'Ask **our officer** at [the site](https://nestprep.app/help) or '
        '[email address].',
      );
      expect(spans.map((span) => span.runtimeType), [
        LegalText,
        LegalText,
        LegalText,
        LegalLink,
        LegalText,
        LegalPlaceholder,
        LegalText,
      ]);
      expect(spans[1].isBold, isTrue);
      expect(spans[1].text, 'our officer');
      final link = spans[3] as LegalLink;
      expect(link.text, 'the site');
      expect(link.target, Uri.parse('https://nestprep.app/help'));
      expect(spans[5].text, 'email address');
    });

    test('a placeholder or a link inside bold keeps what it is', () {
      final spans = parseLegalInline(
        '**[legal entity name] and [x](mailto:a@b.c)**',
      );
      expect(spans.first, isA<LegalPlaceholder>());
      expect(spans.first.isBold, isTrue);
      expect(spans.last, isA<LegalLink>());
      expect(spans.last.isBold, isTrue);
    });

    test('follows only the web and email', () {
      for (final target in [
        'https://a.b',
        'http://a.b',
        'mailto:privacy@a.b',
      ]) {
        expect(parseLegalInline('[x]($target)').single, isA<LegalLink>());
      }
      for (final target in ['javascript:alert(1)', 'file:///etc', 'tel:123']) {
        expect(
          () => parseLegalInline('[x]($target)'),
          throwsFormatException,
          reason: target,
        );
      }
    });

    test('plain text is plain', () {
      final spans = parseLegalInline('Nothing special here.');
      expect(spans.single, isA<LegalText>());
      expect(spans.single.isBold, isFalse);
    });
  });
}

String _text(List<LegalSpan> spans) => spans.map((span) => span.text).join();
