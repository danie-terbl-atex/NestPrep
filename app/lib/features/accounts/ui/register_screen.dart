import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../../onboarding/model/onboarding_step.dart';
import '../../onboarding/ui/onboarding_header.dart';
import '../state/register_controller.dart';
import 'register_form.dart';
import 'sign_in_screen.dart';

/// Creating an account with an address and a password (accounts ADR-0002),
/// the first step of the creator's way in (onboarding ADR-0001).
///
/// On success nothing happens here: registering signs the person in, the
/// session's auth stream fires, and the router moves them on to the consent
/// step and the household gate (accounts ADR-0007).
class RegisterScreen extends StatelessWidget {
  const RegisterScreen({super.key});

  static const path = '/register';

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<RegisterController>();
    final failure = controller.failure;
    final nest = NestTheme.of(context);
    return NestScaffold(
      backdrop: const NestWaves(),
      leading: NestIconButton(
        icon: LucideIcons.arrowLeft,
        label: AppCopy.back,
        onPressed: () => context.go(SignInScreen.path),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const OnboardingHeader(
              step: CreatorStep.account,
              title: AppCopy.registerTitle,
              twigPose: NestTwigPose.welcome,
              twigLine: OnboardingCopy.twigHello,
              twigAction: NestTwigAction.wave,
            ),
            const SizedBox(height: NestSpace.xl),
            if (failure != null) ...[
              NestBanner(
                message: AppCopy.failure(failure),
                tone: NestBannerTone.danger,
              ),
              const SizedBox(height: NestSpace.lg),
            ],
            const RegisterForm(),
            const SizedBox(height: NestSpace.lg),
            Text(
              AppCopy.registerHasAccount,
              style: nest.text.caption.copyWith(color: nest.colors.inkTertiary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: NestSpace.sm),
            NestButton(
              label: AppCopy.registerSignInInstead,
              variant: NestButtonVariant.ghost,
              size: NestButtonSize.small,
              onPressed: controller.isBusy
                  ? null
                  : () => context.go(SignInScreen.path),
            ),
          ],
        ),
      ),
    );
  }
}
