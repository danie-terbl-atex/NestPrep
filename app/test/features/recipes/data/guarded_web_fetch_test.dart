import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:nestprep/app/app_version.dart';
import 'package:nestprep/features/recipes/data/guarded_web_fetch.dart';
import 'package:nestprep/features/recipes/data/public_address.dart';
import 'package:nestprep/shared/failure/app_failure.dart';

const _page = 'https://example.com/recipe';

Future<List<InternetAddress>> _public(String host) async => [
  InternetAddress('93.184.216.34'),
];

http.StreamedResponse _answer(
  int status, {
  String body = 'hello',
  Map<String, String> headers = const {'content-type': 'text/html'},
}) => http.StreamedResponse(
  Stream.value(utf8.encode(body)),
  status,
  headers: headers,
);

void main() {
  late List<http.BaseRequest> sent;

  GuardedWebFetch fetchOver(
    http.StreamedResponse Function(http.BaseRequest request) answer, {
    HostResolver resolve = _public,
    Duration timeout = const Duration(seconds: 8),
  }) => GuardedWebFetch(
    client: MockClient.streaming((request, _) async {
      sent.add(request);
      return answer(request);
    }),
    resolve: resolve,
    timeout: timeout,
  );

  Future<FetchedWebFile> get(GuardedWebFetch fetch, {int maxBytes = 1024}) =>
      fetch.get(
        _page,
        maxBytes: maxBytes,
        accept: 'text/html',
        accepts: (type) => type?.contains('html') ?? true,
      );

  Matcher refusedWith(RecipeImportProblem problem) => throwsA(
    isA<RecipeImportFailure>().having((f) => f.problem, 'problem', problem),
  );

  setUp(() => sent = []);

  test(
    'asks as itself, never a browser, and follows nothing on its own',
    () async {
      final file = await get(fetchOver((_) => _answer(200)));

      expect(file.url, _page);
      expect(utf8.decode(file.bytes), 'hello');
      final request = sent.single;
      expect(
        request.headers['User-Agent'],
        'NestPrep/${AppVersion.name} (+https://nestprep.io)',
      );
      expect(request.headers['User-Agent'], isNot(contains('Mozilla')));
      expect(request.followRedirects, isFalse);
    },
  );

  group('a private DNS answer', () {
    for (final address in ['192.168.1.1', '10.0.0.2', '127.0.0.1', '::1']) {
      test('$address is refused at the first hop, before asking', () async {
        final fetch = fetchOver(
          (_) => _answer(200),
          resolve: (_) async => [InternetAddress(address)],
        );
        await expectLater(
          get(fetch),
          refusedWith(RecipeImportProblem.linkNotPublic),
        );
        expect(sent, isEmpty);
      });
    }

    test('among public ones is still refused', () async {
      final fetch = fetchOver(
        (_) => _answer(200),
        resolve: (_) async => [
          InternetAddress('93.184.216.34'),
          InternetAddress('192.168.1.1'),
        ],
      );
      await expectLater(
        get(fetch),
        refusedWith(RecipeImportProblem.linkNotPublic),
      );
      expect(sent, isEmpty);
    });

    test('is refused after a redirect, before following it', () async {
      final fetch = fetchOver(
        (request) => _answer(
          302,
          headers: {'location': 'https://rebound.example.org/admin'},
        ),
        resolve: (host) async => [
          InternetAddress(
            host == 'rebound.example.org' ? '192.168.1.1' : '93.184.216.34',
          ),
        ],
      );
      await expectLater(
        get(fetch),
        refusedWith(RecipeImportProblem.linkNotPublic),
      );
      expect(sent.map((request) => request.url.host), ['example.com']);
    });
  });

  group('redirects', () {
    test('a relative one is followed, and the last link is the page', () async {
      final file = await get(
        fetchOver(
          (request) => request.url.path == '/recipe'
              ? _answer(301, headers: {'location': '/moved'})
              : _answer(200),
        ),
      );
      expect(file.url, 'https://example.com/moved');
    });

    test('one to a name that is not public is refused', () async {
      await expectLater(
        get(
          fetchOver(
            (_) => _answer(302, headers: {'location': 'http://192.168.1.1/'}),
          ),
        ),
        refusedWith(RecipeImportProblem.linkNotPublic),
      );
      expect(sent, hasLength(1));
    });

    test('five are followed', () async {
      var hops = 0;
      final file = await get(
        fetchOver(
          (_) => ++hops <= GuardedWebFetch.maxRedirects
              ? _answer(302, headers: {'location': '/hop$hops'})
              : _answer(200),
        ),
      );
      expect(file.url, 'https://example.com/hop5');
    });

    test('a sixth is not', () async {
      var hops = 0;
      await expectLater(
        get(
          fetchOver(
            (_) => _answer(302, headers: {'location': '/hop${++hops}'}),
          ),
        ),
        refusedWith(RecipeImportProblem.pageUnreachable),
      );
      expect(sent, hasLength(GuardedWebFetch.maxRedirects + 1));
    });
  });

  group('the size cap', () {
    test('holds while streaming, whatever the headers claimed', () async {
      var wasCancelled = false;
      final body = StreamController<List<int>>(
        onCancel: () => wasCancelled = true,
      );
      final fetch = fetchOver(
        (_) => http.StreamedResponse(
          body.stream,
          200,
          headers: const {'content-type': 'text/html'},
        ),
      );
      final asked = get(fetch, maxBytes: 10);
      body.add(List.filled(8, 65));
      body.add(List.filled(8, 65));
      await expectLater(
        asked,
        refusedWith(RecipeImportProblem.pageUnreachable),
      );
      expect(wasCancelled, isTrue);
    });

    test('holds on a content-length, before reading', () async {
      final fetch = fetchOver(
        (_) => http.StreamedResponse(
          const Stream.empty(),
          200,
          contentLength: 11,
          headers: const {'content-type': 'text/html'},
        ),
      );
      await expectLater(
        get(fetch, maxBytes: 10),
        refusedWith(RecipeImportProblem.pageUnreachable),
      );
    });

    test('lets exactly the cap through', () async {
      final file = await get(
        fetchOver((_) => _answer(200, body: 'x' * 10)),
        maxBytes: 10,
      );
      expect(file.bytes, hasLength(10));
    });
  });

  group('what went wrong is told apart', () {
    for (final status in [401, 402, 403, 429, 451, 400, 418]) {
      test('$status is the site refusing', () async {
        await expectLater(
          get(fetchOver((_) => _answer(status))),
          refusedWith(RecipeImportProblem.pageRefused),
        );
      });
    }

    for (final status in [404, 410]) {
      test('$status is the page being gone', () async {
        await expectLater(
          get(fetchOver((_) => _answer(status))),
          refusedWith(RecipeImportProblem.pageNotFound),
        );
      });
    }

    for (final status in [500, 503, 304]) {
      test('$status is the site being unreachable', () async {
        await expectLater(
          get(fetchOver((_) => _answer(status))),
          refusedWith(RecipeImportProblem.pageUnreachable),
        );
      });
    }

    test('a name that will not resolve is unreachable', () async {
      await expectLater(
        get(
          fetchOver(
            (_) => _answer(200),
            resolve: (_) async => throw const SocketException('no such host'),
          ),
        ),
        refusedWith(RecipeImportProblem.pageUnreachable),
      );
    });

    test('no answers at all is unreachable', () async {
      await expectLater(
        get(fetchOver((_) => _answer(200), resolve: (_) async => const [])),
        refusedWith(RecipeImportProblem.pageUnreachable),
      );
    });

    test('a client failure is unreachable', () async {
      final fetch = GuardedWebFetch(
        client: MockClient((_) async => throw http.ClientException('reset')),
        resolve: _public,
      );
      await expectLater(
        get(fetch),
        refusedWith(RecipeImportProblem.pageUnreachable),
      );
    });

    test('a site that never answers is too slow', () async {
      final never = Completer<http.StreamedResponse>();
      final fetch = GuardedWebFetch(
        client: MockClient.streaming((_, _) => never.future),
        resolve: _public,
        timeout: const Duration(milliseconds: 20),
      );
      await expectLater(
        get(fetch),
        refusedWith(RecipeImportProblem.pageUnreachable),
      );
    });

    test('a body that stalls is too slow', () async {
      final body = StreamController<List<int>>();
      final fetch = fetchOver(
        (_) => http.StreamedResponse(
          body.stream,
          200,
          headers: const {'content-type': 'text/html'},
        ),
        timeout: const Duration(milliseconds: 20),
      );
      await expectLater(
        get(fetch),
        refusedWith(RecipeImportProblem.pageUnreachable),
      );
      await body.close();
    });

    test('a type the caller will not read is not read', () async {
      await expectLater(
        get(
          fetchOver(
            (_) => _answer(
              200,
              headers: const {'content-type': 'application/pdf'},
            ),
          ),
        ),
        refusedWith(RecipeImportProblem.noRecipe),
      );
    });

    test('a link that is not public never reaches the network', () async {
      final fetch = fetchOver((_) => _answer(200));
      await expectLater(
        fetch.get(
          'http://192.168.1.1/',
          maxBytes: 10,
          accept: '*/*',
          accepts: (_) => true,
        ),
        refusedWith(RecipeImportProblem.linkNotPublic),
      );
      expect(sent, isEmpty);
    });
  });

  group('an address', () {
    for (final address in [
      '93.184.216.34',
      '8.8.8.8',
      '172.15.0.1',
      '172.32.0.1',
      '100.63.0.1',
      '2606:2800:220:1:248:1893:25c8:1946',
      '::ffff:93.184.216.34',
      '64:ff9b::5db8:d822',
      '2002:5db8:d822::1',
    ]) {
      test('$address is public', () {
        expect(isPublicAddress(InternetAddress(address)), isTrue);
      });
    }

    for (final address in [
      '0.0.0.0',
      '10.1.2.3',
      '100.64.0.1',
      '127.0.0.1',
      '169.254.169.254',
      '172.16.0.1',
      '172.31.255.255',
      '192.0.2.1',
      '192.168.0.1',
      '198.18.0.1',
      '224.0.0.1',
      '255.255.255.255',
      '::',
      '::1',
      'fc00::1',
      'fd12:3456::1',
      'fe80::1',
      'ff02::1',
      '2001:db8::1',
      '::ffff:192.168.1.1',
      '::ffff:127.0.0.1',
      '64:ff9b::c0a8:0101',
      '2002:c0a8:0101::1',
    ]) {
      test('$address is not', () {
        expect(isPublicAddress(InternetAddress(address)), isFalse);
      });
    }
  });
}
