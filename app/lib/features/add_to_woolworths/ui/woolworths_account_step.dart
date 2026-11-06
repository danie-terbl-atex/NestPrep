import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../../../shared/copy/woolworths_copy.dart';
import '../state/woolworths_link_controller.dart';

/// The member's Woolworths email and password, sent from this phone to
/// Woolworths only. The password is cleared once it has been sent. The password
/// manager may fill a saved Woolworths login, but is never asked to save one
/// here, where it would be filed under NestPrep (accounts ADR-0013).
class WoolworthsAccountStep extends StatefulWidget {
  const WoolworthsAccountStep({required this.onLinked, super.key});

  final VoidCallback onLinked;

  @override
  State<WoolworthsAccountStep> createState() => _WoolworthsAccountStepState();
}

class _WoolworthsAccountStepState extends State<WoolworthsAccountStep> {
  final _email = TextEditingController();
  final _password = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<WoolworthsLinkController>();
    final fieldFailure = controller.fieldFailure;
    final canSignIn =
        _email.text.trim().contains('@') &&
        _password.text.isNotEmpty &&
        !controller.isBusy;
    void edited(String _) {
      controller.clearFieldFailure();
      setState(() {});
    }

    return AutofillGroup(
      onDisposeAction: AutofillContextAction.cancel,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          NestTextField(
            key: const ValueKey('woolworths-email'),
            autofillHints: const [AutofillHints.username, AutofillHints.email],
            label: WoolworthsCopy.emailLabel,
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            textCapitalization: TextCapitalization.none,
            onChanged: edited,
          ),
          const SizedBox(height: NestSpace.md),
          NestTextField(
            key: const ValueKey('woolworths-password'),
            label: WoolworthsCopy.passwordLabel,
            controller: _password,
            obscureText: true,
            autofillHints: const [AutofillHints.password],
            textInputAction: TextInputAction.done,
            textCapitalization: TextCapitalization.none,
            errorText: fieldFailure == null
                ? null
                : AppCopy.failure(fieldFailure),
            onChanged: edited,
            onSubmitted: (_) => canSignIn ? _signIn(controller) : null,
          ),
          const SizedBox(height: NestSpace.lg),
          NestButton(
            key: const ValueKey('woolworths-sign-in'),
            label: WoolworthsCopy.signIn,
            icon: LucideIcons.logIn,
            isLoading: controller.isBusy,
            onPressed: canSignIn ? () => _signIn(controller) : null,
          ),
        ],
      ),
    );
  }

  Future<void> _signIn(WoolworthsLinkController controller) async {
    final password = _password.text;
    _password.clear();
    final linked = await controller.signIn(
      email: _email.text,
      password: password,
    );
    if (linked) widget.onLinked();
  }
}
