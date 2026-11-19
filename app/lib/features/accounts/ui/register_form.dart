import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../state/register_controller.dart';

/// The name, address and password that make an account (accounts ADR-0002),
/// shared by the register screen and the invite way in (household ADR-0011).
///
/// Registering signs the person in and the router moves them on, so nothing
/// happens here on success except asking the password manager to save what
/// worked (accounts ADR-0013). Why an attempt failed is the screen's to show.
class RegisterForm extends StatefulWidget {
  const RegisterForm({super.key});

  /// The project's policy is eight characters; refusing a shorter one here
  /// saves a round trip to be told the same thing (accounts ADR-0002).
  static const minimumPasswordLength = 8;

  @override
  State<RegisterForm> createState() => _RegisterFormState();
}

class _RegisterFormState extends State<RegisterForm> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();

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
      _password.text.length >= RegisterForm.minimumPasswordLength;

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<RegisterController>();
    return AutofillGroup(
      onDisposeAction: AutofillContextAction.cancel,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          NestTextField(
            label: AppCopy.registerNameLabel,
            hint: AppCopy.registerNameHint,
            controller: _name,
            enabled: !controller.isBusy,
            textCapitalization: TextCapitalization.words,
            autofillHints: const [AutofillHints.name],
            textInputAction: TextInputAction.next,
            prefixIcon: LucideIcons.user,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: NestSpace.md),
          NestTextField(
            label: AppCopy.signInEmailLabel,
            controller: _email,
            enabled: !controller.isBusy,
            keyboardType: TextInputType.emailAddress,
            autofillHints: const [AutofillHints.username, AutofillHints.email],
            textCapitalization: TextCapitalization.none,
            textInputAction: TextInputAction.next,
            prefixIcon: LucideIcons.atSign,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: NestSpace.md),
          NestTextField(
            label: AppCopy.signInPasswordLabel,
            hint: AppCopy.registerPasswordHint,
            controller: _password,
            enabled: !controller.isBusy,
            obscureText: true,
            autofillHints: const [AutofillHints.newPassword],
            textCapitalization: TextCapitalization.none,
            textInputAction: TextInputAction.done,
            prefixIcon: LucideIcons.lock,
            onChanged: (_) => setState(() {}),
            onSubmitted: (_) => _submit(controller),
          ),
          const SizedBox(height: NestSpace.xl),
          NestButton(
            label: AppCopy.registerSubmit,
            isLoading: controller.isBusy,
            onPressed: _canSubmit ? () => _submit(controller) : null,
          ),
        ],
      ),
    );
  }

  void _submit(RegisterController controller) {
    if (!_canSubmit || controller.isBusy) return;
    unawaited(_register(controller));
  }

  Future<void> _register(RegisterController controller) async {
    final registered = await controller.register(
      name: _name.text,
      email: _email.text,
      password: _password.text,
    );
    if (registered) TextInput.finishAutofillContext();
  }
}
