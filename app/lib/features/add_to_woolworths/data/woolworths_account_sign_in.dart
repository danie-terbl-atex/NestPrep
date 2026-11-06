import '../model/woolworths_sign_in.dart';

/// Signing in to the member's own Woolworths account from the phone
/// (add-to-woolworths ADR-0001): the password goes from here to Woolworths
/// and nowhere else, and only the refresh token comes back. Nothing is kept.
/// Each refusal arrives as a `WoolworthsFailure`.
abstract interface class WoolworthsAccountSignIn {
  Future<WoolworthsSignInStep> signIn({
    required WoolworthsCognito cognito,
    required String email,
    required String password,
  });

  Future<WoolworthsSignInStep> answer(WoolworthsCodeAsked asked, String code);
}
