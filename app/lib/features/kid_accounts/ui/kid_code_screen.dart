import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../../../shared/copy/kid_copy.dart';
import '../../accounts/ui/sign_in_screen.dart';
import '../state/kid_code_controller.dart';
import 'kid_code_field.dart';

/// The kid's way in (accounts ADR-0003): a friendly hello, six big tiles, and
/// one button. No email, no password, nothing to remember — a grown-up made
/// the code a minute ago and is standing right there.
class KidCodeScreen extends StatelessWidget {
  const KidCodeScreen({super.key});

  static const path = '/sign-in/kid';

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<KidCodeController>();
    final nest = NestTheme.of(context);
    final failure = controller.failure;
    return NestScaffold(
      leading: NestIconButton(
        icon: LucideIcons.arrowLeft,
        label: AppCopy.back,
        variant: NestIconButtonVariant.plain,
        onPressed: () => context.go(SignInScreen.path),
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              const NestRiseIn(
                child: Center(
                  child: NestIconTile(
                    icon: LucideIcons.hand,
                    tint: NestTileTint.butter,
                    size: NestSize.mark,
                    iconSize: NestSize.iconMark,
                  ),
                ),
              ),
              const SizedBox(height: NestSpace.xl),
              NestRiseIn(
                index: 1,
                child: Text(
                  KidCopy.codeTitle,
                  textAlign: TextAlign.center,
                  style: nest.text.display,
                ),
              ),
              const SizedBox(height: NestSpace.sm),
              NestRiseIn(
                index: 2,
                child: Text(
                  KidCopy.codeBody,
                  textAlign: TextAlign.center,
                  style: nest.text.bodySecondary,
                ),
              ),
              const SizedBox(height: NestSpace.xxl),
              NestRiseIn(
                index: 3,
                child: KidCodeField(
                  code: controller.code,
                  onChanged: controller.setCode,
                  onSubmitted: controller.submit,
                ),
              ),
              if (failure != null) ...[
                const SizedBox(height: NestSpace.lg),
                NestBanner(
                  message: AppCopy.failure(failure),
                  tone: NestBannerTone.danger,
                ),
              ],
              const SizedBox(height: NestSpace.xxl),
              NestRiseIn(
                index: 4,
                child: NestButton(
                  label: KidCopy.codeSubmit,
                  icon: LucideIcons.rocket,
                  isLoading: controller.isSubmitting,
                  onPressed: controller.isComplete ? controller.submit : null,
                ),
              ),
              const SizedBox(height: NestSpace.md),
              NestRiseIn(
                index: 5,
                child: NestButton(
                  label: KidCopy.codeBackToSignIn,
                  variant: NestButtonVariant.ghost,
                  onPressed: () => context.go(SignInScreen.path),
                ),
              ),
              const SizedBox(height: NestSpace.xxl),
            ],
          ),
        ),
      ),
    );
  }
}
