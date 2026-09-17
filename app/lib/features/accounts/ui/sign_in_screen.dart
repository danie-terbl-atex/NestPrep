import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/backend_target.dart';
import '../../../app/emulator_accounts.dart';
import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../state/session_controller.dart';
import 'seeded_account_picker.dart';

/// The way in (accounts ADR-0001). Google is the only real provider; the seeded
/// shortcut below it exists only on an emulator build.
class SignInScreen extends StatelessWidget {
  const SignInScreen({super.key});

  static const path = '/sign-in';

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
                const _SignInMasthead(),
                const SizedBox(height: NestSpace.xxxl),
                if (failure != null) ...[
                  NestBanner(
                    message: AppCopy.failure(failure),
                    tone: NestBannerTone.danger,
                  ),
                  const SizedBox(height: NestSpace.lg),
                ],
                NestButton(
                  label: AppCopy.signInWithGoogle,
                  icon: Icons.login,
                  isLoading: session.isSigningIn,
                  onPressed: session.signInWithGoogle,
                ),
                if (BackendTarget.fromEnvironment() ==
                    BackendTarget.emulator) ...[
                  const SizedBox(height: NestSpace.xxl),
                  SeededAccountPicker(
                    accounts: EmulatorAccount.all,
                    isBusy: session.isSigningIn,
                    onPick: (account) => session.signInWithSeededUser(
                      email: account.email,
                      password: EmulatorAccount.password,
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

class _SignInMasthead extends StatelessWidget {
  const _SignInMasthead();

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    return Column(
      children: [
        const NestIconTile(
          icon: Icons.home_rounded,
          size: NestSize.avatarLarge,
        ),
        const SizedBox(height: NestSpace.xl),
        Text(
          AppCopy.appName,
          style: nest.text.display.copyWith(color: nest.colors.ink),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: NestSpace.sm),
        Text(
          AppCopy.signInTagline,
          style: nest.text.body.copyWith(color: nest.colors.inkSecondary),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
