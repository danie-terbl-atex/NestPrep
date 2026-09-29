import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../state/register_controller.dart';
import 'sign_in_screen.dart';

/// Creating an account with an address and a password (accounts ADR-0002).
///
/// On success nothing happens here: registering signs the person in, the
/// session's auth stream fires, and the router sends them to the verify screen.
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  static const path = '/register';

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();

  /// The project's policy is eight characters; refusing a shorter one here
  /// saves a round trip to be told the same thing (accounts ADR-0002).
  static const _minimumPasswordLength = 8;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  bool get _canSubmit =>
      _name.text.trim().isNotEmpty &&
      _email.text.trim().isNotEmpty &&
      _password.text.length >= _minimumPasswordLength;

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<RegisterController>();
    final failure = controller.failure;
    return NestScaffold(
      title: AppCopy.registerTitle,
      leading: NestIconButton(
        icon: Icons.arrow_back,
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
            NestTextField(
              label: AppCopy.registerNameLabel,
              hint: AppCopy.registerNameHint,
              controller: _name,
              enabled: !controller.isBusy,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.next,
              prefixIcon: Icons.person_outline,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: NestSpace.md),
            NestTextField(
              label: AppCopy.signInEmailLabel,
              controller: _email,
              enabled: !controller.isBusy,
              keyboardType: TextInputType.emailAddress,
              textCapitalization: TextCapitalization.none,
              textInputAction: TextInputAction.next,
              prefixIcon: Icons.alternate_email,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: NestSpace.md),
            NestTextField(
              label: AppCopy.signInPasswordLabel,
              hint: AppCopy.registerPasswordHint,
              controller: _password,
              enabled: !controller.isBusy,
              obscureText: true,
              textCapitalization: TextCapitalization.none,
              textInputAction: TextInputAction.done,
              prefixIcon: Icons.lock_outline,
              onChanged: (_) => setState(() {}),
              onSubmitted: (_) => _submit(controller),
            ),
            const SizedBox(height: NestSpace.xl),
            NestButton(
              label: AppCopy.registerSubmit,
              isLoading: controller.isBusy,
              onPressed: _canSubmit ? () => _submit(controller) : null,
            ),
            const SizedBox(height: NestSpace.lg),
            Text(
              AppCopy.registerHasAccount,
              style: NestTheme.of(context).text.caption
                  .copyWith(color: NestTheme.of(context).colors.inkTertiary),
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

  void _submit(RegisterController controller) {
    if (!_canSubmit || controller.isBusy) return;
    unawaited(
      controller.register(
        name: _name.text,
        email: _email.text,
        password: _password.text,
      ),
    );
  }
}
