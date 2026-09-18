import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/backend_target.dart';
import '../../../app/emulator_accounts.dart';
import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../state/session_controller.dart';
import 'seeded_account_picker.dart';
import 'sign_in_welcome.dart';

/// The way in (accounts ADR-0001). Google is the only real provider; the seeded
/// shortcut below it exists only on an emulator build.
///
/// The picture, the name and the line arrive in that order and then stop
/// (`FE-15`). A failure banner is **not** part of the choreography: when
/// something has gone wrong it appears at once, because making somebody wait
/// for an apology to fade in is the wrong moment for delight.
class SignInScreen extends StatelessWidget {
  const SignInScreen({super.key});

  static const path = '/sign-in';

  /// Where the way in sits in the entrance, counted from the welcome's own
  /// last step so the button follows the tagline rather than racing it.
  static const _waysInStep = 10;

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionController>();
    final failure = session.signInFailure;
    return NestScaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SignInWelcome(),
                const SizedBox(height: NestSpace.xxxl),
                if (failure != null) ...[
                  NestBanner(
                    message: AppCopy.failure(failure),
                    tone: NestBannerTone.danger,
                  ),
                  const SizedBox(height: NestSpace.lg),
                ],
                NestRiseIn(
                  index: _waysInStep,
                  child: NestButton(
                    label: AppCopy.signInWithGoogle,
                    icon: Icons.login,
                    isLoading: session.isSigningIn,
                    onPressed: session.signInWithGoogle,
                  ),
                ),
                if (BackendTarget.fromEnvironment() ==
                    BackendTarget.emulator) ...[
                  const SizedBox(height: NestSpace.xxl),
                  NestRiseIn(
                    index: _waysInStep + 1,
                    child: SeededAccountPicker(
                      accounts: EmulatorAccount.all,
                      isBusy: session.isSigningIn,
                      onPick: (account) => session.signInWithSeededUser(
                        email: account.email,
                        password: EmulatorAccount.password,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
