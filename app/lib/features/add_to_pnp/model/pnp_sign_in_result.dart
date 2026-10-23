import 'package:flutter/foundation.dart';

/// What Pick n Pay's sign-in page handed back on its redirect to
/// `www.pnp.co.za/oidc_login` (add-to-pnp ADR-0003 §3): a code and the
/// `state` the link was started with — or nothing, when the member backed
/// out or Pick n Pay refused.
@immutable
final class PnpSignInResult {
  const PnpSignInResult._({this.code, this.state});

  /// The redirect [url] read, or null when it is not the redirect at all.
  static PnpSignInResult? fromRedirect(Uri url) {
    if (url.scheme != 'https' ||
        url.host != redirectHost ||
        url.path != redirectPath) {
      return null;
    }
    final code = url.queryParameters['code'];
    final state = url.queryParameters['state'];
    final hasCode = code != null && code.isNotEmpty;
    final hasState = state != null && state.isNotEmpty;
    if (url.queryParameters.containsKey('error') || !hasCode || !hasState) {
      return const PnpSignInResult._();
    }
    return PnpSignInResult._(code: code, state: state);
  }

  static const redirectHost = 'www.pnp.co.za';
  static const redirectPath = '/oidc_login';

  /// The only host the sign-in page may navigate within.
  static const loginHost = 'login.pnp.co.za';

  final String? code;
  final String? state;

  bool get isSignedIn => code != null && state != null;
}
