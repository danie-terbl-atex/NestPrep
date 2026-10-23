import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../shared/failure/app_failure.dart';
import '../../../shared/log/app_log.dart';

/// One answer from Pick n Pay's commerce API: its status and its JSON.
typedef PnpReply = ({int status, Object? json});

/// Pick n Pay's commerce API (`www.pnp.co.za/pnphybris/v2/pnp-spa`) as the
/// phone calls it — no cookie, no bearer, nothing about the member
/// (add-to-pnp ADR-0002). Each call has a timeout (`BE-19`); a 429 stops
/// every call until its `Retry-After` has passed. Failures arrive as a
/// `PnpFailure`, never as an HTTP error.
final class PnpOccClient {
  PnpOccClient({
    http.Client? client,
    DateTime Function()? now,
    this.timeout = const Duration(seconds: 8),
  }) : _client = client ?? http.Client(),
       _now = now ?? DateTime.now;

  static const host = 'www.pnp.co.za';
  static const basePath = '/pnphybris/v2/pnp-spa';
  static const _defaultCoolDown = Duration(seconds: 30);

  final http.Client _client;
  final DateTime Function() _now;
  final Duration timeout;
  DateTime? _coolDownUntil;

  Future<Object?> get(String path, Map<String, String> query) async =>
      _ok(await send('GET', path, query));

  Future<Object?> post(
    String path,
    Map<String, String> query,
    Map<String, Object?> body,
  ) async => _ok(await send('POST', path, query, body: body));

  /// Any answer but a 429 or a failure to reach PnP, for a caller that reads
  /// a refusal itself.
  Future<PnpReply> send(
    String method,
    String path,
    Map<String, String> query, {
    Map<String, Object?>? body,
  }) async {
    final coolDownUntil = _coolDownUntil;
    if (coolDownUntil != null && _now().isBefore(coolDownUntil)) {
      throw const PnpFailure(PnpProblem.catalogueBusy);
    }
    final request =
        http.Request(
            method,
            Uri.https(host, '$basePath$path', {
              ...query,
              'lang': 'en',
              'curr': 'ZAR',
            }),
          )
          ..headers.addAll(const {
            'accept': 'application/json',
            'content-type': 'application/json',
          });
    if (body != null) request.body = jsonEncode(body);
    final http.Response response;
    try {
      response = await http.Response.fromStream(
        await _client.send(request).timeout(timeout),
      ).timeout(timeout);
    } on TimeoutException catch (error) {
      throw _unreachable('timeout', error);
    } on http.ClientException catch (error) {
      throw _unreachable('client', error);
    }
    if (response.statusCode == 429) {
      _coolDownUntil = _now().add(_retryAfter(response));
      AppLog.failure('pnp catalogue', code: '429');
      throw const PnpFailure(PnpProblem.catalogueBusy);
    }
    return (status: response.statusCode, json: _decode(response));
  }

  Object? _ok(PnpReply reply) {
    if (reply.status < 200 || reply.status >= 300) {
      throw _unreachable('${reply.status}', null);
    }
    return reply.json;
  }

  Object? _decode(http.Response response) {
    if (response.bodyBytes.isEmpty) return null;
    try {
      return jsonDecode(utf8.decode(response.bodyBytes));
    } on FormatException catch (error) {
      // A refusal's page need not be JSON; its status says enough.
      final status = response.statusCode;
      if (status < 200 || status >= 300) return null;
      AppLog.failure('pnp catalogue', code: 'not-json', error: error);
      throw const PnpFailure(PnpProblem.catalogueChanged);
    }
  }

  Duration _retryAfter(http.Response response) {
    final seconds = int.tryParse(response.headers['retry-after'] ?? '');
    return seconds == null || seconds <= 0
        ? _defaultCoolDown
        : Duration(seconds: seconds);
  }

  PnpFailure _unreachable(String code, Object? error) {
    AppLog.failure('pnp catalogue', code: code, error: error);
    return const PnpFailure(PnpProblem.catalogueUnreachable);
  }
}
