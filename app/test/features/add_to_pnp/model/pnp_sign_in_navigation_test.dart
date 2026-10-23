import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/add_to_pnp/model/pnp_sign_in_navigation.dart';

/// The sign-in page's rules (add-to-pnp ADR-0003 §3, ADR-0005), without a
/// web view: only Pick n Pay's sign-in host, the
/// redirect read and never loaded, and anywhere else refused out loud.
void main() {
  group('a navigation', () {
    test('within the sign-in host loads', () {
      expect(
        PnpSignInNavigation.decide(Uri.parse('https://login.pnp.co.za/login')),
        isA<PnpNavigationAllowed>(),
      );
    });

    test('to the redirect is read, never loaded', () {
      final verdict = PnpSignInNavigation.decide(
        Uri.parse('https://www.pnp.co.za/oidc_login?code=abc&state=s1'),
      );
      expect(verdict, isA<PnpNavigationRedirect>());
      final result = (verdict as PnpNavigationRedirect).result;
      expect(result.code, 'abc');
      expect(result.isSignedIn, isTrue);
    });

    for (final elsewhere in [
      'https://storefront.pnp.co.za/forgot-password',
      'https://www.pnp.co.za/register',
      'http://login.pnp.co.za/login',
      'https://example.com/',
    ]) {
      test('to $elsewhere is refused', () {
        expect(
          PnpSignInNavigation.decide(Uri.parse(elsewhere)),
          isA<PnpNavigationRefused>(),
        );
      });
    }

    test('that is not a URL is refused', () {
      expect(PnpSignInNavigation.decide(null), isA<PnpNavigationRefused>());
    });
  });

  group('an HTTP error', () {
    final showing = Uri.parse('https://login.pnp.co.za/login');

    test('for the page being shown fails the page', () {
      expect(
        PnpSignInNavigation.isThePage(
          Uri.parse('https://login.pnp.co.za/login?x=1'),
          showing,
        ),
        isTrue,
      );
    });

    test('for one of its images does not', () {
      expect(
        PnpSignInNavigation.isThePage(
          Uri.parse('https://login.pnp.co.za/images/logo.png'),
          showing,
        ),
        isFalse,
      );
      expect(PnpSignInNavigation.isThePage(null, showing), isFalse);
    });
  });
}
