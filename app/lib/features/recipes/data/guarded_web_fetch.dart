import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import '../../../app/app_version.dart';
import '../../../shared/failure/app_failure.dart';
import 'page_link.dart';
import 'public_address.dart';

typedef HostResolver = Future<List<InternetAddress>> Function(String host);

final class FetchedWebFile {
  const FetchedWebFile({
    required this.url,
    required this.bytes,
    required this.contentType,
  });

  final String url;
  final Uint8List bytes;
  final String? contentType;
}

final class GuardedWebFetch {
  GuardedWebFetch({
    required this._client,
    this._resolve = InternetAddress.lookup,
    this.timeout = const Duration(seconds: 8),
  });

  final http.Client _client;
  final HostResolver _resolve;
  final Duration timeout;

  static const maxRedirects = 5;
  static const userAgent = 'NestPrep/${AppVersion.name} (+https://nestprep.io)';

  static const _refused = RecipeImportFailure(RecipeImportProblem.pageRefused);
  static const _notFound = RecipeImportFailure(
    RecipeImportProblem.pageNotFound,
  );
  static const _unreachable = RecipeImportFailure(
    RecipeImportProblem.pageUnreachable,
  );
  static const _notPublic = RecipeImportFailure(
    RecipeImportProblem.linkNotPublic,
  );
  static const _notWanted = RecipeImportFailure(RecipeImportProblem.noRecipe);

  /// Throws a `RecipeImportFailure`, whose problem says why.
  Future<FetchedWebFile> get(
    String url, {
    required int maxBytes,
    required String accept,
    required bool Function(String? contentType) accepts,
  }) async {
    final abort = Completer<void>();
    final expiry = Timer(timeout, abort.complete);
    try {
      return await _follow(
        url,
        maxBytes: maxBytes,
        accept: accept,
        accepts: accepts,
        abort: abort.future,
      ).timeout(timeout);
    } on TimeoutException {
      throw _unreachable;
    } on IOException {
      throw _unreachable;
    } on http.ClientException {
      throw _unreachable;
    } on StateError {
      // dart:io refuses plain http where the platform forbids it.
      throw _unreachable;
    } finally {
      expiry.cancel();
    }
  }

  Future<FetchedWebFile> _follow(
    String start, {
    required int maxBytes,
    required String accept,
    required bool Function(String? contentType) accepts,
    required Future<void> abort,
  }) async {
    var link = pageLink(start);
    for (var hop = 0; hop <= maxRedirects; hop++) {
      if (link == null) throw _notPublic;
      final url = Uri.parse(link);
      await _refusePrivate(url.host);
      final response = await _client.send(
        http.AbortableRequest('GET', url, abortTrigger: abort)
          ..followRedirects = false
          ..headers['User-Agent'] = userAgent
          ..headers['Accept'] = accept,
      );
      final status = response.statusCode;
      if (status >= 200 && status < 300) {
        if (!accepts(response.headers['content-type'])) {
          await _discard(response);
          throw _notWanted;
        }
        return FetchedWebFile(
          url: link,
          bytes: await _capped(response, maxBytes),
          contentType: response.headers['content-type'],
        );
      }
      await _discard(response);
      final location = response.headers['location'];
      if (status >= 300 && status < 400 && location != null) {
        link = _next(url, location);
        continue;
      }
      throw switch (status) {
        404 || 410 => _notFound,
        >= 400 && < 500 => _refused,
        _ => _unreachable,
      };
    }
    throw _unreachable;
  }

  static String? _next(Uri from, String location) {
    final target = Uri.tryParse(location);
    return target == null ? null : pageLink(from.resolveUri(target).toString());
  }

  Future<void> _refusePrivate(String host) async {
    final answers = await _resolve(host);
    if (answers.isEmpty) throw _unreachable;
    if (!answers.every(isPublicAddress)) throw _notPublic;
  }

  static Future<void> _discard(http.StreamedResponse response) =>
      response.stream.take(0).drain<void>();

  static Future<Uint8List> _capped(
    http.StreamedResponse response,
    int maxBytes,
  ) async {
    if ((response.contentLength ?? 0) > maxBytes) {
      await _discard(response);
      throw _unreachable;
    }
    final bytes = BytesBuilder(copy: false);
    await for (final chunk in response.stream) {
      bytes.add(chunk);
      if (bytes.length > maxBytes) throw _unreachable;
    }
    return bytes.takeBytes();
  }
}
