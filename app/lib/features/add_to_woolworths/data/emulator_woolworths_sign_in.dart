import '../../../shared/failure/app_failure.dart';
import '../model/woolworths_sign_in.dart';
import 'woolworths_account_sign_in.dart';

/// The emulator's stand-in for Woolworths' sign-in: any email and password
/// sign in, an email containing `code` asks for `123456` first, and the
/// refresh token is the one `EmulatorWoolworths` in the Functions accepts.
final class EmulatorWoolworthsSignIn implements WoolworthsAccountSignIn {
  const EmulatorWoolworthsSignIn();

  static const refreshToken = 'emulator-woolworths-refresh';
  static const code = '123456';

  @override
  Future<WoolworthsSignInStep> signIn({
    required WoolworthsCognito cognito,
    required String email,
    required String password,
  }) async => email.contains('code')
      ? WoolworthsCodeAsked(
          cognito: cognito,
          challengeName: 'EMAIL_OTP',
          session: 'emulator-session',
          username: email,
          sentTo: 'p***@o***.nest',
        )
      : const WoolworthsSignedIn(refreshToken);

  @override
  Future<WoolworthsSignInStep> answer(
    WoolworthsCodeAsked asked,
    String code,
  ) async => code == EmulatorWoolworthsSignIn.code
      ? const WoolworthsSignedIn(refreshToken)
      : throw const WoolworthsFailure(WoolworthsProblem.wrongCode);
}
