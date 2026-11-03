import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/photo_frames/model/shared_page.dart';

void main() {
  group('the first web link in shared text', () {
    const recipe = 'https://www.example.com/recipes/lemon-tart?serves=6#steps';

    final cases = {
      recipe: recipe,
      'Lemon tart $recipe via Chrome': recipe,
      'Lemon tart\n$recipe\nShared from Chrome': recipe,
      'Look at this: $recipe.': recipe,
      '“$recipe”': recipe,
      '($recipe)': recipe,
      'HTTPS://Example.com/Tart!': 'HTTPS://Example.com/Tart',
      'https://en.wikipedia.org/wiki/Tart_(pastry)':
          'https://en.wikipedia.org/wiki/Tart_(pastry)',
      'see (https://en.wikipedia.org/wiki/Tart_(pastry))':
          'https://en.wikipedia.org/wiki/Tart_(pastry)',
      'http://first.example.com then https://second.example.com':
          'http://first.example.com',
      'ftp://files.example.com and https://example.com/a':
          'https://example.com/a',
    };
    for (final MapEntry(key: text, value: link) in cases.entries) {
      test(text, () => expect(SharedPage.firstWebLink(text), link));
    }

    for (final text in [
      '',
      'Lemon tart, no link',
      'example.com/recipes',
      'https://',
      'mailto:sam@example.com',
    ]) {
      test(
        'none in "$text"',
        () => expect(SharedPage.firstWebLink(text), isNull),
      );
    }
  });

  group('the share link', () {
    test('carries the page and its title', () {
      final page = SharedPage.fromLink(
        Uri.parse(
          'nestprep://share?url=${Uri.encodeQueryComponent('https://example.com/tart?a=1&b=2')}'
          '&title=${Uri.encodeQueryComponent('Lemon tart & cream')}',
        ),
      );
      expect(
        page,
        const SharedPage(
          url: 'https://example.com/tart?a=1&b=2',
          title: 'Lemon tart & cream',
        ),
      );
      expect(page!.site, 'example.com');
    });

    test('has no title when none is given or it is blank', () {
      expect(
        SharedPage.fromLink(
          Uri.parse('nestprep://share?url=https://a.example.com'),
        ),
        const SharedPage(url: 'https://a.example.com'),
      );
      expect(
        SharedPage.fromLink(
          Uri.parse('nestprep://share?url=https://a.example.com&title=%20%0A'),
        )!.title,
        isNull,
      );
    });

    test('finds the link in text a phone passed on whole', () {
      final text = Uri.encodeQueryComponent(
        'Lemon tart https://example.com/tart via Chrome',
      );
      expect(
        SharedPage.fromLink(Uri.parse('nestprep://share?url=$text'))!.url,
        'https://example.com/tart',
      );
    });

    test('with nothing to show is still a share, with no page', () {
      expect(
        SharedPage.fromLink(Uri.parse('nestprep://share?title=Notes')),
        const SharedPage(title: 'Notes'),
      );
      expect(
        SharedPage.fromLink(Uri.parse('nestprep://share?url=not%20a%20link')),
        const SharedPage(),
      );
    });

    test('is not an invite, a frame code or another site', () {
      for (final link in [
        'nestprep://invite/ABCD2345',
        'nestprep://frame/K7MQ9Z',
        'https://example.com/share?url=https://example.com',
        'other://share?url=https://example.com',
      ]) {
        expect(SharedPage.fromLink(Uri.parse(link)), isNull, reason: link);
      }
    });

    test('a title is made one tidy line, no longer than the server keeps', () {
      expect(
        SharedPage.cleanTitle('  Lemon\ttart\n\u0007 & cream  '),
        'Lemon tart & cream',
      );
      expect(
        SharedPage.cleanTitle('x' * 300),
        hasLength(SharedPage.titleMaxLength),
      );
    });
  });
}
