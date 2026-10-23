import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/add_to_pnp/model/pnp_sign_in_result.dart';

/// What PnP's sign-in page hands back is read from its redirect URL only
/// (add-to-pnp ADR-0003 §3).
void main() {
  test('the redirect carries the code and the state', () {
    final result = PnpSignInResult.fromRedirect(
      Uri.parse('https://www.pnp.co.za/oidc_login?code=abc&state=xyz'),
    )!;
    expect(result.isSignedIn, isTrue);
    expect(result.code, 'abc');
    expect(result.state, 'xyz');
  });

  test('an error or a missing code is a sign-in that did not finish', () {
    for (final url in [
      'https://www.pnp.co.za/oidc_login?error=access_denied&state=xyz',
      'https://www.pnp.co.za/oidc_login?state=xyz',
      'https://www.pnp.co.za/oidc_login?code=abc',
    ]) {
      expect(PnpSignInResult.fromRedirect(Uri.parse(url))!.isSignedIn, isFalse);
    }
  });

  test('anything else is not the redirect at all', () {
    for (final url in [
      'https://login.pnp.co.za/login',
      'http://www.pnp.co.za/oidc_login?code=abc&state=xyz',
      'https://evil.example/oidc_login?code=abc&state=xyz',
      'https://www.pnp.co.za/other?code=abc&state=xyz',
    ]) {
      expect(PnpSignInResult.fromRedirect(Uri.parse(url)), isNull);
    }
  });
}
