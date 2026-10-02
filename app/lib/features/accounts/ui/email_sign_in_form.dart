import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';

/// The address-and-password half of the sign-in screen (accounts ADR-0002).
///
/// Holds the two text controllers and nothing else: whether the attempt is in
/// flight, and why it failed, belong to the session and are rendered by the
/// screen above (`FE-07`). Kept apart from [SeededAccountPicker], which is the
/// emulator's shortcut past this form and must never become it.
class EmailSignInForm extends StatefulWidget {
  const EmailSignInForm({
    required this.isBusy,
    required this.onSubmit,
    required this.onForgotPassword,
    super.key,
  });

  final bool isBusy;
  final void Function({required String email, required String password})
  onSubmit;
  final VoidCallback onForgotPassword;

  @override
  State<EmailSignInForm> createState() => _EmailSignInFormState();
}

class _EmailSignInFormState extends State<EmailSignInForm> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _passwordFocus = FocusNode();

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  /// Empty fields are refused here rather than at Firebase: a round trip to be
  /// told to type something is a round trip nobody needed.
  bool get _canSubmit =>
      _email.text.trim().isNotEmpty && _password.text.isNotEmpty;

  void _submit() {
    if (!_canSubmit || widget.isBusy) return;
    widget.onSubmit(email: _email.text, password: _password.text);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        NestTextField(
          label: AppCopy.signInEmailLabel,
          controller: _email,
          enabled: !widget.isBusy,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          textCapitalization: TextCapitalization.none,
          prefixIcon: LucideIcons.atSign,
          onChanged: (_) => setState(() {}),
          onSubmitted: (_) => _passwordFocus.requestFocus(),
        ),
        const SizedBox(height: NestSpace.md),
        NestTextField(
          label: AppCopy.signInPasswordLabel,
          controller: _password,
          focusNode: _passwordFocus,
          enabled: !widget.isBusy,
          obscureText: true,
          textInputAction: TextInputAction.done,
          textCapitalization: TextCapitalization.none,
          prefixIcon: LucideIcons.lock,
          onChanged: (_) => setState(() {}),
          onSubmitted: (_) => _submit(),
        ),
        const SizedBox(height: NestSpace.lg),
        NestButton(
          label: AppCopy.signInWithEmail,
          isLoading: widget.isBusy,
          onPressed: _canSubmit ? _submit : null,
        ),
        const SizedBox(height: NestSpace.sm),
        NestButton(
          label: AppCopy.signInForgotPassword,
          variant: NestButtonVariant.ghost,
          size: NestButtonSize.small,
          onPressed: widget.isBusy ? null : widget.onForgotPassword,
        ),
      ],
    );
  }
}
