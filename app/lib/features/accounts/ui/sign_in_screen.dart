import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../app/backend_target.dart';
import '../../../app/emulator_accounts.dart';
import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../../../shared/copy/kid_copy.dart';
import '../../kid_accounts/ui/kid_code_screen.dart';
import '../state/session_controller.dart';
import 'email_sign_in_form.dart';
import 'forgot_password_screen.dart';
import 'register_screen.dart';
import 'seeded_account_picker.dart';
import 'sign_in_welcome.dart';

/// The way in (accounts ADR-0001, ADR-0002). Two providers: Google, and an
/// address with a password. The seeded shortcut below them exists only on an
/// emulator build and is a different widget on purpose — a throwaway password
/// list must never become the production form.
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
                const SizedBox(height: NestSpace.xl),
                const NestRiseIn(index: _waysInStep + 1, child: _OrDivider()),
                const SizedBox(height: NestSpace.xl),
                NestRiseIn(
                  index: _waysInStep + 2,
                  child: EmailSignInForm(
                    isBusy: session.isSigningIn,
                    onSubmit: session.signInWithEmail,
                    onForgotPassword: () =>
                        context.go(ForgotPasswordScreen.path),
                  ),
                ),
                const SizedBox(height: NestSpace.lg),
                const NestRiseIn(
                  index: _waysInStep + 3,
                  child: _WayInPrompt(label: AppCopy.signInNoAccount),
                ),
                const SizedBox(height: NestSpace.sm),
                NestRiseIn(
                  index: _waysInStep + 3,
                  child: NestButton(
                    label: AppCopy.signInCreateAccount,
                    variant: NestButtonVariant.outline,
                    onPressed: session.isSigningIn
                        ? null
                        : () => context.go(RegisterScreen.path),
                  ),
                ),
                // A child has no email and no password: a grown-up makes a
                // code (accounts ADR-0003).
                const SizedBox(height: NestSpace.xxl),
                const NestRiseIn(
                  index: _waysInStep + 4,
                  child: _WayInPrompt(label: KidCopy.signInPrompt),
                ),
                const SizedBox(height: NestSpace.sm),
                NestRiseIn(
                  index: _waysInStep + 4,
                  child: NestButton(
                    label: KidCopy.signInWithCode,
                    icon: Icons.child_care_rounded,
                    variant: NestButtonVariant.tonal,
                    onPressed: session.isSigningIn
                        ? null
                        : () => context.go(KidCodeScreen.path),
                  ),
                ),
                if (BackendTarget.fromEnvironment() ==
                    BackendTarget.emulator) ...[
                  const SizedBox(height: NestSpace.xxl),
                  NestRiseIn(
                    index: _waysInStep + 5,
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

/// The line between the two providers. A hairline and a word, so neither way in
/// reads as the fallback for the other.
class _OrDivider extends StatelessWidget {
  const _OrDivider();

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    final line = Expanded(
      child: Divider(color: nest.colors.outline, height: 1),
    );
    return Row(
      children: [
        line,
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: NestSpace.md),
          child: Text(
            AppCopy.signInOr,
            style: nest.text.caption.copyWith(color: nest.colors.inkTertiary),
          ),
        ),
        line,
      ],
    );
  }
}

/// The small line above a way in that is not the main one, so a button on its
/// own does not have to carry the whole explanation.
class _WayInPrompt extends StatelessWidget {
  const _WayInPrompt({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    return Text(
      label,
      style: nest.text.caption.copyWith(color: nest.colors.inkTertiary),
      textAlign: TextAlign.center,
    );
  }
}
