import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:image/image.dart' as img;
import 'package:nestprep/features/recipes/data/guarded_web_fetch.dart';
import 'package:nestprep/features/recipes/data/recipe_image_fetcher.dart';
import 'package:nestprep/features/recipes/data/recipe_page_reader.dart';
import 'package:nestprep/shared/failure/app_failure.dart';

const _link = 'https://example.com/bobotie';

GuardedWebFetch _over(
  http.Response Function(http.BaseRequest request) answer, {
  void Function()? onAsk,
  String address = '93.184.216.34',
}) => GuardedWebFetch(
  client: MockClient((request) async {
    onAsk?.call();
    return answer(request);
  }),
  resolve: (_) async => [InternetAddress(address)],
);

http.Response _html(String body, {int status = 200}) => http.Response(
  body,
  status,
  headers: const {'content-type': 'text/html; charset=utf-8'},
);

int _crc32(List<int> bytes) {
  var crc = 0xffffffff;
  for (final byte in bytes) {
    crc ^= byte;
    for (var bit = 0; bit < 8; bit++) {
      crc = crc & 1 == 1 ? (crc >>> 1) ^ 0xedb88320 : crc >>> 1;
    }
  }
  return (crc ^ 0xffffffff) & 0xffffffff;
}

List<int> _chunk(String type, List<int> data) {
  final typed = [...ascii.encode(type), ...data];
  return [
    ...(ByteData(4)..setUint32(0, data.length)).buffer.asUint8List(),
    ...typed,
    ...(ByteData(4)..setUint32(0, _crc32(typed))).buffer.asUint8List(),
  ];
}

/// A PNG that says it is whatever size it likes: the signature and a valid IHDR,
/// then nothing a decoder would ever get to.
Uint8List _pngClaiming(int width, int height) {
  final ihdr = ByteData(13)
    ..setUint32(0, width)
    ..setUint32(4, height)
    ..setUint8(8, 8)
    ..setUint8(9, 6);
  return Uint8List.fromList([
    0x89,
    0x50,
    0x4e,
    0x47,
    0x0d,
    0x0a,
    0x1a,
    0x0a,
    ..._chunk('IHDR', ihdr.buffer.asUint8List()),
    ..._chunk('IEND', const []),
  ]);
}

void main() {
  Matcher refusedWith(RecipeImportProblem problem) => throwsA(
    isA<RecipeImportFailure>().having((f) => f.problem, 'problem', problem),
  );

  group('reading a page', () {
    test('a page with a recipe comes back, off the main isolate', () async {
      final page = await HttpRecipePageReader(
        _over(
          (_) => _html(
            '<html><head><title>Bobotie</title>'
            '<script type="application/ld+json">{"@type":"Recipe"}</script>'
            '</head><body></body></html>',
          ),
        ),
      ).read(_link);
      expect(page.url, _link);
      expect(page.title, 'Bobotie');
      expect(page.jsonLd, ['{"@type":"Recipe"}']);
      expect(page.text, isEmpty);
    });

    test('the final link, after a redirect, is the one sent', () async {
      final page = await HttpRecipePageReader(
        _over(
          (request) => request.url.path == '/bobotie'
              ? http.Response(
                  '',
                  301,
                  headers: const {'location': '/recipes/bobotie'},
                )
              : _html(
                  '<html><head><script type="application/ld+json">'
                  '{"@type":"Recipe","image":"pic.jpg"}'
                  '</script></head></html>',
                ),
        ),
      ).read(_link);
      expect(page.url, 'https://example.com/recipes/bobotie');
      expect(page.imageUrls, ['https://example.com/recipes/pic.jpg']);
    });

    test('a refusal page with little on it spends no model call', () async {
      await expectLater(
        HttpRecipePageReader(_over((_) => _html('<h1>Just a moment</h1>')))
            .read(_link),
        refusedWith(RecipeImportProblem.noRecipe),
      );
    });

    for (final type in ['application/pdf', 'image/jpeg', 'application/json']) {
      test('$type is not read', () async {
        await expectLater(
          HttpRecipePageReader(
            _over(
              (_) => http.Response(
                '{"@type":"Recipe"}',
                200,
                headers: {'content-type': type},
              ),
            ),
          ).read(_link),
          refusedWith(RecipeImportProblem.noRecipe),
        );
      });
    }

    test('a refused site is said to have refused', () async {
      await expectLater(
        HttpRecipePageReader(
          _over((_) => _html('Payment required', status: 402)),
        ).read(_link),
        refusedWith(RecipeImportProblem.pageRefused),
      );
    });

    test('a private DNS answer never gets to the page', () async {
      var asks = 0;
      await expectLater(
        HttpRecipePageReader(
          _over(
            (_) => _html('<p>never</p>'),
            onAsk: () => asks++,
            address: '192.168.1.1',
          ),
        ).read(_link),
        refusedWith(RecipeImportProblem.linkNotPublic),
      );
      expect(asks, 0);
    });
  });

  group('fetching a picture', () {
    final png = img.encodePng(img.Image(width: 4, height: 4));

    http.Response picture(List<int> bytes, {String? type = 'image/png'}) =>
        http.Response.bytes(bytes, 200, headers: {'content-type': ?type});

    test('a real picture comes back', () async {
      expect(
        await HttpRecipeImageFetcher(_over((_) => picture(png)))
            .fetch('https://cdn.example.com/a.png'),
        png,
      );
    });

    test('is checked like a page: a private answer gives nothing', () async {
      var asks = 0;
      expect(
        await HttpRecipeImageFetcher(
          _over((_) => picture(png), onAsk: () => asks++, address: '10.0.0.1'),
        ).fetch('https://cdn.example.com/a.png'),
        isNull,
      );
      expect(asks, 0);
    });

    test('nothing, for a link that is not public', () async {
      expect(
        await HttpRecipeImageFetcher(_over((_) => picture(png)))
            .fetch('http://192.168.1.1/a.png'),
        isNull,
      );
    });

    test('nothing, past 8 MB, without throwing', () async {
      expect(
        await HttpRecipeImageFetcher(
          _over((_) => picture(Uint8List(8 * 1024 * 1024 + 1))),
        ).fetch('https://cdn.example.com/a.png'),
        isNull,
      );
    });

    test('nothing, for a 404 or an HTML page', () async {
      expect(
        await HttpRecipeImageFetcher(_over((_) => http.Response('gone', 404)))
            .fetch('https://cdn.example.com/a.png'),
        isNull,
      );
      expect(
        await HttpRecipeImageFetcher(
          _over((_) => _html('<p>not a picture</p>')),
        ).fetch('https://cdn.example.com/a.png'),
        isNull,
      );
    });

    test('nothing, for bytes that are not a picture', () async {
      expect(
        await HttpRecipeImageFetcher(
          _over((_) => picture(utf8.encode('this is not a picture'))),
        ).fetch('https://cdn.example.com/a.png'),
        isNull,
      );
    });

    test('nothing, for a small file claiming to be enormous', () async {
      final bomb = _pngClaiming(30000, 30000);
      expect(bomb.length, lessThan(100));
      expect(HttpRecipeImageFetcher.isSafeToDecode(bomb), isFalse);
      expect(
        await HttpRecipeImageFetcher(_over((_) => picture(bomb)))
            .fetch('https://cdn.example.com/a.png'),
        isNull,
      );
    });

    test('a large but ordinary claim is let through', () {
      expect(
        HttpRecipeImageFetcher.isSafeToDecode(_pngClaiming(6000, 4000)),
        isTrue,
      );
    });
  });
}
