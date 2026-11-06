import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../shared/failure/app_failure.dart';
import '../../../shared/log/app_log.dart';

/// The public Woolworths calls the phone makes, with no cookie and nothing
/// about the member: Constructor's search and `woolworths.co.za/server/*`,
/// which needs only a Woolworths `Referer`. A 429 stops every call until its
/// `Retry-After` has passed.
final class WoolworthsWebClient {
  WoolworthsWebClient({
    http.Client? client,
    DateTime Function()? now,
    this.timeout = const Duration(seconds: 8),
  }) : _client = client ?? http.Client(),
       _now = now ?? DateTime.now;

  static const siteHost = 'www.woolworths.co.za';
  static const _referer = 'https://www.woolworths.co.za/';
  static const _defaultCoolDown = Duration(seconds: 30);

  final http.Client _client;
  final DateTime Function() _now;
  final Duration timeout;
  DateTime? _coolDownUntil;

  Future<Object?> site(String path, Map<String, String> query) => get(
    Uri.https(siteHost, '/server/$path', query),
    headers: const {'referer': _referer},
  );

  Future<Object?> get(Uri uri, {Map<String, String> headers = const {}}) async {
    final coolDownUntil = _coolDownUntil;
    if (coolDownUntil != null && _now().isBefore(coolDownUntil)) {
      throw const WoolworthsFailure(WoolworthsProblem.catalogueBusy);
    }
    final http.Response response;
    try {
      response = await _client
          .get(uri, headers: {'accept': 'application/json', ...headers})
          .timeout(timeout);
    } on TimeoutException catch (error) {
      throw _unreachable('timeout', error);
    } on http.ClientException catch (error) {
      throw _unreachable('client', error);
    }
    final status = response.statusCode;
    if (status == 429) {
      _coolDownUntil = _now().add(_retryAfter(response));
      AppLog.failure('woolworths catalogue', code: '429');
      throw const WoolworthsFailure(WoolworthsProblem.catalogueBusy);
    }
    if (status < 200 || status >= 300) throw _unreachable('$status', null);
    try {
      return jsonDecode(utf8.decode(response.bodyBytes));
    } on FormatException catch (error) {
      AppLog.failure('woolworths catalogue', code: 'not-json', error: error);
      throw const WoolworthsFailure(WoolworthsProblem.catalogueChanged);
    }
  }

  Duration _retryAfter(http.Response response) {
    final seconds = int.tryParse(response.headers['retry-after'] ?? '');
    return seconds == null || seconds <= 0
        ? _defaultCoolDown
        : Duration(seconds: seconds);
  }

  WoolworthsFailure _unreachable(String code, Object? error) {
    AppLog.failure('woolworths catalogue', code: code, error: error);
    return const WoolworthsFailure(WoolworthsProblem.catalogueUnreachable);
  }
}
