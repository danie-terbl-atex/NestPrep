import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../state/password_reset_controller.dart';
import 'sign_in_screen.dart';

/// Asking for a link to set a new password (accounts ADR-0002).
///
/// The success message is the same whether or not the address had an account.
/// That is deliberate: a screen that says "no such account" is a way to find
/// out who has one.
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  static const path = '/forgot-password';

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _email = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<PasswordResetController>();
    final nest = NestTheme.of(context);
    final failure = controller.failure;
    final canSubmit = _email.text.trim().isNotEmpty && !controller.isBusy;

    return NestScaffold(
      title: AppCopy.forgotPasswordTitle,
      leading: NestIconButton(
        icon: LucideIcons.arrowLeft,
        label: AppCopy.back,
        onPressed: () => context.go(SignInScreen.path),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (failure != null) ...[
              NestBanner(
                message: AppCopy.failure(failure),
                tone: NestBannerTone.danger,
              ),
              const SizedBox(height: NestSpace.lg),
            ],
            if (controller.wasSent)
              const NestBanner(
                message: AppCopy.forgotPasswordSent,
                tone: NestBannerTone.success,
              )
            else ...[
              Text(
                AppCopy.forgotPasswordBlurb,
                style: nest.text.body.copyWith(color: nest.colors.inkSecondary),
              ),
              const SizedBox(height: NestSpace.xl),
              NestTextField(
                label: AppCopy.signInEmailLabel,
                controller: _email,
                enabled: !controller.isBusy,
                keyboardType: TextInputType.emailAddress,
                textCapitalization: TextCapitalization.none,
                textInputAction: TextInputAction.done,
                prefixIcon: LucideIcons.atSign,
                onChanged: (_) => setState(() {}),
                onSubmitted: (_) => _submit(controller),
              ),
              const SizedBox(height: NestSpace.xl),
              NestButton(
                label: AppCopy.forgotPasswordSubmit,
                isLoading: controller.isBusy,
                onPressed: canSubmit ? () => _submit(controller) : null,
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _submit(PasswordResetController controller) {
    if (_email.text.trim().isEmpty || controller.isBusy) return;
    unawaited(controller.send(_email.text));
  }
}
