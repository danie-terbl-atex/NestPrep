import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/recipes/data/recipe_page_extractor.dart';
import 'package:nestprep/features/recipes/model/recipe_page.dart';

const _url = 'https://example.com/recipes/bobotie';

String _ld(Object? value) =>
    '<script type="application/ld+json">${jsonEncode(value)}</script>';

const _recipe = {
  '@type': 'Recipe',
  'name': 'Bobotie',
  'image': 'https://cdn.example.com/hero.jpg',
};

String _pageWith({String head = '', String body = ''}) =>
    '<!doctype html><html><head><title>Bobotie</title>$head</head>'
    '<body>$body</body></html>';

final _words = 'Mix the mince with the spices and bake it until golden. ' * 40;

void main() {
  RecipePage? extract(String html) => extractRecipePage(url: _url, html: html);

  group('finds the recipe in the JSON-LD', () {
    test('as the only thing in a block', () {
      final page = extract(_pageWith(head: _ld(_recipe)))!;
      expect(jsonDecode(page.jsonLd.single), _recipe);
    });

    test('in an @graph, beside other things', () {
      final page = extract(
        _pageWith(
          head: _ld({
            '@context': 'https://schema.org',
            '@graph': [
              {'@type': 'WebSite', 'name': 'Example'},
              _recipe,
              {'@type': 'BreadcrumbList'},
            ],
          }),
        ),
      )!;
      expect(jsonDecode(page.jsonLd.single), _recipe);
    });

    test('in an array', () {
      final page = extract(
        _pageWith(
          head: _ld([
            {'@type': 'Organization'},
            _recipe,
          ]),
        ),
      )!;
      expect(jsonDecode(page.jsonLd.single), _recipe);
    });

    test('in an @graph inside an array', () {
      final page = extract(
        _pageWith(
          head: _ld([
            {
              '@graph': [_recipe],
            },
          ]),
        ),
      )!;
      expect(page.jsonLd, hasLength(1));
    });

    test('with a list for its @type', () {
      final page = extract(
        _pageWith(
          head: _ld({
            '@type': ['Recipe', 'NewsArticle'],
            'name': 'Bobotie',
          }),
        ),
      )!;
      expect(jsonDecode(page.jsonLd.single), containsPair('name', 'Bobotie'));
    });

    test('with a malformed block beside a good one', () {
      final page = extract(
        _pageWith(
          head:
              '<script type="application/ld+json">{"@type": "Recipe", </script>'
              '${_ld(_recipe)}',
        ),
      )!;
      expect(jsonDecode(page.jsonLd.single), _recipe);
    });

    test('with raw newlines and a trailing comma, which sites do write', () {
      final page = extract(
        _pageWith(
          head:
              '<script type="application/ld+json">\n'
              '{"@type": "Recipe",\n"name": "Bobotie\nfrom Gran",\n}\n'
              '</script>',
        ),
      )!;
      expect(jsonDecode(page.jsonLd.single), containsPair('@type', 'Recipe'));
    });

    test('with a charset on its type', () {
      final page = extract(
        _pageWith(
          head:
              '<script type="application/ld+json; charset=utf-8">'
              '${jsonEncode(_recipe)}</script>',
        ),
      )!;
      expect(page.jsonLd, hasLength(1));
    });

    test('no more than the contract allows', () {
      final page = extract(
        _pageWith(
          head: _ld([
            for (var i = 0; i < 15; i++) {'@type': 'Recipe', 'name': 'R$i'},
          ]),
        ),
      )!;
      expect(page.jsonLd, hasLength(RecipePage.maxJsonLdBlocks));
    });
  });

  group('sends text only when there is no recipe', () {
    test('a recipe in the JSON-LD means no text at all', () {
      final page = extract(
        _pageWith(head: _ld(_recipe), body: '<p>$_words</p>'),
      )!;
      expect(page.jsonLd, isNotEmpty);
      expect(page.text, isEmpty);
    });

    test('JSON-LD that is not a recipe means the words', () {
      final page = extract(
        _pageWith(head: _ld({'@type': 'Article'}), body: '<p>$_words</p>'),
      )!;
      expect(page.jsonLd, isEmpty);
      expect(page.text, startsWith('Mix the mince'));
    });

    test('a recipe too big to send falls back to the words', () {
      final page = extract(
        _pageWith(
          head: _ld({'@type': 'Recipe', 'review': 'r' * 70000}),
          body: '<p>$_words</p>',
        ),
      )!;
      expect(page.jsonLd, isEmpty);
      expect(page.text, startsWith('Mix the mince'));
    });

    test('words are visible words, spaced, from what a person reads', () {
      final page = extract(
        _pageWith(
          body:
              '<header>Site header</header><nav>Menu</nav>'
              '<script>var hidden = 1;</script><style>.x{}</style>'
              '<noscript>Turn on JavaScript</noscript>'
              '<form>Sign up</form><aside>Related</aside>'
              '<main><p>First</p><p>Second</p><p>$_words</p></main>'
              '<footer>Site footer</footer>',
        ),
      )!;
      expect(page.text, startsWith('First Second Mix'));
      for (final hidden in [
        'Site header',
        'Menu',
        'hidden',
        '.x',
        'JavaScript',
        'Sign up',
        'Related',
        'Site footer',
      ]) {
        expect(page.text, isNot(contains(hidden)));
      }
    });
  });

  group('spends no model call on', () {
    test('a refusal page', () {
      expect(
        extract(
          _pageWith(
            body: '<h1>Access denied</h1><p>Please verify you are human.</p>',
          ),
        ),
        isNull,
      );
    });

    test('a page just short of the threshold', () {
      final body = 'x ' * ((RecipePage.minTextChars - 1) ~/ 2);
      expect(extract(_pageWith(body: '<p>$body</p>')), isNull);
    });

    test('a page of only scripts', () {
      expect(
        extract(_pageWith(body: '<script>${'var a = 1;' * 900}</script>')),
        isNull,
      );
    });

    test('and spends one on a page at the threshold', () {
      final body = 'x' * RecipePage.minTextChars;
      expect(extract(_pageWith(body: '<p>$body</p>')), isNotNull);
    });

    test('the smallest real text-only page clears it easily', () {
      expect(RecipePage.minTextChars, lessThan(4400));
    });
  });

  group('the 60,000 character cap', () {
    test('holds across the title and a long text', () {
      final page = extract(
        _pageWith(body: '<p>${'long words here ' * 20000}</p>'),
      )!;
      expect(page.chars, lessThanOrEqualTo(RecipePage.maxChars));
      expect(page.text.length, RecipePage.maxChars - 'Bobotie'.length);
    });

    test('holds across several recipes, leaving out what does not fit', () {
      final page = extract(
        _pageWith(
          head: _ld([
            for (var i = 0; i < 4; i++)
              {'@type': 'Recipe', 'name': 'R$i', 'body': 'b' * 25000},
          ]),
        ),
      )!;
      expect(page.jsonLd, hasLength(2));
      expect(page.chars, lessThanOrEqualTo(RecipePage.maxChars));
    });

    test('holds a long title to the contract', () {
      final page = extract(
        '<html><head><title>${'t' * 400}</title></head>'
        '<body>${_ld(_recipe)}</body></html>',
      )!;
      expect(page.title, hasLength(RecipePage.maxTitleChars));
    });

    test('never cuts an emoji in half', () {
      final page = extract(
        '<html><head><title>a</title></head><body><p>'
        '${'x' * (RecipePage.maxChars - 2)}😀😀</p></body></html>',
      )!;
      expect(page.chars, lessThanOrEqualTo(RecipePage.maxChars));
      expect(
        page.text.codeUnitAt(page.text.length - 1) & 0xfc00,
        isNot(0xd800),
      );
      expect(() => utf8.encode(page.text), returnsNormally);
    });
  });

  group('images', () {
    test('from a string, an array and an ImageObject, JSON-LD first', () {
      final page = extract(
        _pageWith(
          head:
              '<meta property="og:image" content="https://cdn.example.com/og.jpg">'
              '<meta name="twitter:image" content="https://cdn.example.com/tw.jpg">'
              '${_ld({
                '@type': 'Recipe',
                'image': [
                  'https://cdn.example.com/a.jpg',
                  {'@type': 'ImageObject', 'url': 'https://cdn.example.com/b.jpg'},
                  ['https://cdn.example.com/c.jpg'],
                ],
              })}',
        ),
      )!;
      expect(page.imageUrls, [
        'https://cdn.example.com/a.jpg',
        'https://cdn.example.com/b.jpg',
        'https://cdn.example.com/c.jpg',
        'https://cdn.example.com/og.jpg',
        'https://cdn.example.com/tw.jpg',
      ]);
    });

    test('resolved to absolute links against the page', () {
      final page = extract(
        _pageWith(
          head:
              '<meta property="og:image" content="/img/og.jpg">'
              '<meta name="twitter:image" content="//cdn.example.com/tw.jpg">'
              '${_ld({'@type': 'Recipe', 'image': 'hero.jpg'})}',
        ),
      )!;
      expect(page.imageUrls, [
        'https://example.com/recipes/hero.jpg',
        'https://example.com/img/og.jpg',
        'https://cdn.example.com/tw.jpg',
      ]);
    });

    test('deduped, and never more than six', () {
      final page = extract(
        _pageWith(
          head:
              '<meta property="og:image" content="https://cdn.example.com/0.jpg">'
              '${_ld({
                '@type': 'Recipe',
                'image': [for (var i = 0; i < 9; i++) 'https://cdn.example.com/$i.jpg'],
              })}',
        ),
      )!;
      expect(page.imageUrls, [
        for (var i = 0; i < RecipePage.maxImages; i++)
          'https://cdn.example.com/$i.jpg',
      ]);
    });

    test('never one that is not a public link', () {
      final page = extract(
        _pageWith(
          head: _ld({
            '@type': 'Recipe',
            'image': [
              'http://192.168.1.1/x.jpg',
              'data:image/png;base64,AAAA',
              'https://nas.local/x.jpg',
              'https://cdn.example.com/ok.jpg',
            ],
          }),
        ),
      )!;
      expect(page.imageUrls, ['https://cdn.example.com/ok.jpg']);
    });

    test('a text-only page still offers its social picture', () {
      final page = extract(
        _pageWith(
          head: '<meta property="og:image" content="https://cdn.example.com/og.jpg">',
          body: '<p>$_words</p>',
        ),
      )!;
      expect(page.imageUrls, ['https://cdn.example.com/og.jpg']);
    });
  });

  group('the bytes', () {
    test('are read as Latin-1 only when the server says so', () {
      expect(
        decodedPage(latin1.encode('café'), 'text/html; charset=ISO-8859-1'),
        'café',
      );
      expect(decodedPage(utf8.encode('café'), 'text/html'), 'café');
    });

    test('that are not valid UTF-8 do not throw', () {
      expect(
        () => decodedPage(latin1.encode('café'), 'text/html'),
        returnsNormally,
      );
    });
  });
}
