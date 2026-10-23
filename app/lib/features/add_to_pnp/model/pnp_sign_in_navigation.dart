import 'pnp_sign_in_result.dart';

/// What the sign-in page does with one navigation (add-to-pnp ADR-0003 §3,
/// ADR-0005): carry on within Pick n Pay's sign-in host, hand back the
/// redirect without loading it, or refuse anywhere else — and say so.
sealed class PnpNavigationVerdict {
  const PnpNavigationVerdict();
}

/// Within `login.pnp.co.za`: the page may load it.
final class PnpNavigationAllowed extends PnpNavigationVerdict {
  const PnpNavigationAllowed();
}

/// The redirect to `www.pnp.co.za/oidc_login`: never loaded, read instead.
final class PnpNavigationRedirect extends PnpNavigationVerdict {
  const PnpNavigationRedirect(this.result);

  final PnpSignInResult result;
}

/// Anywhere else — a sign-up or forgot-password page on the website, a
/// link out. Refused, and the member is told where to do it instead.
final class PnpNavigationRefused extends PnpNavigationVerdict {
  const PnpNavigationRefused();
}

/// The rules of Pick n Pay's sign-in page inside the app, without the web
/// view, so every branch is a unit test.
abstract final class PnpSignInNavigation {
  /// What to do with a navigation to [url] — null when it is not a URL.
  static PnpNavigationVerdict decide(Uri? url) {
    if (url == null) return const PnpNavigationRefused();
    final result = PnpSignInResult.fromRedirect(url);
    if (result != null) return PnpNavigationRedirect(result);
    return url.scheme == 'https' && url.host == PnpSignInResult.loginHost
        ? const PnpNavigationAllowed()
        : const PnpNavigationRefused();
  }

  /// Whether an HTTP error answered for [failed] is the page itself rather
  /// than one of its images or scripts: the one being shown.
  static bool isThePage(Uri? failed, Uri? showing) =>
      failed != null &&
      showing != null &&
      failed.host == showing.host &&
      failed.path == showing.path;
}
