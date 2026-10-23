import 'package:flutter/material.dart';

import '../../design/nest_kit.dart';
import '../copy/app_copy.dart';
import '../failure/app_failure.dart';

/// The last step of something that cannot be undone — deleting an account
/// (accounts ADR-0006), closing a household (household ADR-0007): type the
/// word, then the one danger button, which stays shut until the word is there
/// and while the action is on its way (`FE-10`). A refusal shows above it in
/// words.
class TypedConfirm extends StatefulWidget {
  const TypedConfirm({
    required this.label,
    required this.hint,
    required this.buttonLabel,
    required this.busyLabel,
    required this.icon,
    required this.canConfirm,
    required this.isBusy,
    required this.onTyped,
    required this.onConfirm,
    this.failure,
    this.clearsTyped,
    super.key,
  });

  final String label;
  final String hint;
  final String buttonLabel;
  final String busyLabel;
  final IconData icon;
  final bool canConfirm;
  final bool isBusy;
  final AppFailure? failure;
  final ValueChanged<String> onTyped;
  final VoidCallback onConfirm;

  /// A refusal after which the word must be typed again — the controller
  /// forgets it too — so the person confirms what they now see.
  final bool Function(AppFailure failure)? clearsTyped;

  @override
  State<TypedConfirm> createState() => _TypedConfirmState();
}

class _TypedConfirmState extends State<TypedConfirm> {
  final _typed = TextEditingController();

  @override
  void didUpdateWidget(TypedConfirm oldWidget) {
    super.didUpdateWidget(oldWidget);
    final failure = widget.failure;
    if (failure == null || oldWidget.failure == failure) return;
    if (widget.clearsTyped?.call(failure) ?? false) _typed.clear();
  }

  @override
  void dispose() {
    _typed.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final failure = widget.failure;
    return Column(
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
          label: widget.label,
          hint: widget.hint,
          controller: _typed,
          enabled: !widget.isBusy,
          textCapitalization: TextCapitalization.characters,
          textInputAction: TextInputAction.done,
          onChanged: widget.onTyped,
        ),
        const SizedBox(height: NestSpace.lg),
        NestButton(
          label: widget.isBusy ? widget.busyLabel : widget.buttonLabel,
          variant: NestButtonVariant.danger,
          icon: widget.icon,
          isLoading: widget.isBusy,
          onPressed: widget.canConfirm ? widget.onConfirm : null,
        ),
      ],
    );
  }
}
