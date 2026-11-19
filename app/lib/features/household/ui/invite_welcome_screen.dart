import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../../../shared/failure/app_failure.dart';
import '../../accounts/state/register_controller.dart';
import '../../accounts/state/session_controller.dart';
import '../../accounts/ui/email_sign_in_form.dart';
import '../../accounts/ui/forgot_password_screen.dart';
import '../../accounts/ui/register_form.dart';
import '../../accounts/ui/sign_in_or_divider.dart';
import '../../accounts/ui/sign_in_providers.dart';
import '../../onboarding/model/onboarding_step.dart';
import '../../onboarding/ui/onboarding_header.dart';
import '../state/invite_welcome_controller.dart';

/// Step one of three for somebody holding an invite before they have an
/// account (household ADR-0011): whose family it is, then the account made or
/// signed into right here. Consent and joining follow on their own screens;
/// the held invite carries the person through both.
class InviteWelcomeScreen extends StatefulWidget {
  const InviteWelcomeScreen({super.key});

  static const path = '/invite';

  @override
  State<InviteWelcomeScreen> createState() => _InviteWelcomeScreenState();
}

class _InviteWelcomeScreenState extends State<InviteWelcomeScreen> {
  bool _hasAccount = false;

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<InviteWelcomeController>();
    final refusal = controller.refusal;
    return NestScaffold(
      backdrop: const NestWaves(),
      leading: const NestBrandLockup(semanticsLabel: AppCopy.appName),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: NestSpace.huge),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Intro(controller: controller),
            const SizedBox(height: NestSpace.xxl),
            if (controller.isChecking)
              const NestLoadingView(rows: 3)
            else if (refusal != null) ...[
              NestBanner(
                message: AppCopy.failure(HouseholdFailure(refusal)),
                tone: NestBannerTone.danger,
              ),
              const SizedBox(height: NestSpace.xl),
              NestButton(
                label: AccessCopy.inviteWelcomeOtherCode,
                variant: NestButtonVariant.outline,
                onPressed: controller.notNow,
              ),
            ] else
              NestRiseIn(
                index: 2,
                child: _AccountStep(
                  hasAccount: _hasAccount,
                  onChoose: _choose,
                  onNotNow: controller.notNow,
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _choose(bool hasAccount) {
    if (_hasAccount == hasAccount) return;
    context.read<RegisterController>().dismissFailure();
    setState(() => _hasAccount = hasAccount);
  }
}

class _Intro extends StatelessWidget {
  const _Intro({required this.controller});

  final InviteWelcomeController controller;

  @override
  Widget build(BuildContext context) {
    final (title, body) = switch (controller.preview) {
      _ when controller.isChecking => (AccessCopy.inviteLinkChecking, null),
      _ when controller.refusal != null => (
        AccessCopy.inviteWelcomeRefusedTitle,
        null,
      ),
      null => (
        AccessCopy.inviteWelcomeGeneralTitle,
        AccessCopy.inviteWelcomeNext,
      ),
      final found => (
        AccessCopy.inviteLinkTitle(found.householdName),
        AccessCopy.inviteWelcomeInvitedBy(
          memberName: found.memberName,
          role: found.role,
          invitedBy: found.invitedBy,
        ),
      ),
    };
    return OnboardingHeader(
      step: InviteeStep.account,
      title: title,
      body: body,
      twigPose: NestTwigPose.welcome,
      twigLine: OnboardingCopy.twigInvited,
      twigAction: NestTwigAction.wave,
    );
  }
}

class _AccountStep extends StatelessWidget {
  const _AccountStep({
    required this.hasAccount,
    required this.onChoose,
    required this.onNotNow,
  });

  final bool hasAccount;
  final ValueChanged<bool> onChoose;
  final VoidCallback onNotNow;

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionController>();
    final register = context.watch<RegisterController>();
    final isBusy = session.isSigningIn || register.isBusy;
    final failure = hasAccount ? session.signInFailure : register.failure;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        NestSegmentedControl<bool>(
          segments: const [
            NestSegment(value: false, label: AccessCopy.inviteWelcomeNew),
            NestSegment(value: true, label: AccessCopy.inviteWelcomeExisting),
          ],
          selected: hasAccount,
          onSelect: isBusy ? (_) {} : onChoose,
        ),
        const SizedBox(height: NestSpace.xl),
        if (failure != null) ...[
          NestBanner(
            message: AppCopy.failure(failure),
            tone: NestBannerTone.danger,
          ),
          const SizedBox(height: NestSpace.lg),
        ],
        if (hasAccount)
          EmailSignInForm(
            isBusy: session.isSigningIn,
            onSubmit: session.signInWithEmail,
            onForgotPassword: () => context.go(ForgotPasswordScreen.path),
          )
        else
          const RegisterForm(),
        const SizedBox(height: NestSpace.lg),
        const SignInOrDivider(),
        const SizedBox(height: NestSpace.lg),
        SignInProviders(
          isBusy: isBusy,
          onGoogle: session.signInWithGoogle,
          onApple: session.signInWithApple,
        ),
        const SizedBox(height: NestSpace.xl),
        NestButton(
          label: AccessCopy.inviteLinkNotNow,
          variant: NestButtonVariant.ghost,
          onPressed: isBusy ? null : onNotNow,
        ),
      ],
    );
  }
}
