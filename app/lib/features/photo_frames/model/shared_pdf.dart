import 'package:flutter/foundation.dart';

import 'shared_page.dart';

/// A PDF another app shared into NestPrep. The link names only the token the
/// phone filed it under; any app can send that link, so nothing else in it is
/// read (recipes ADR-0009).
@immutable
final class SharedPdf {
  const SharedPdf(this.token);

  final String token;

  static final _token = RegExp(r'^[A-Za-z0-9-]{8,64}$');

  static SharedPdf? fromLink(Uri uri) {
    if (uri.scheme != SharedPage.scheme || uri.host != SharedPage.host) {
      return null;
    }
    final token = uri.queryParameters['pdf'];
    return token != null && _token.hasMatch(token) ? SharedPdf(token) : null;
  }

  @override
  bool operator ==(Object other) => other is SharedPdf && other.token == token;

  @override
  int get hashCode => token.hashCode;
}
