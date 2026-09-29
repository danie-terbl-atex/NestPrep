import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../../../shared/failure/app_failure.dart';

/// The last step of deleting an account: type the word, then the one danger
/// button, which stays shut until the word is there and while a delete is on
/// its way (`FE-10`, accounts ADR-0006). A refusal shows above it in words.
class DeletionConfirm extends StatefulWidget {
  const DeletionConfirm({
    required this.canDelete,
    required this.isDeleting,
    required this.onTyped,
    required this.onDelete,
    this.failure,
    super.key,
  });

  final bool canDelete;
  final bool isDeleting;
  final AppFailure? failure;
  final ValueChanged<String> onTyped;
  final VoidCallback onDelete;

  @override
  State<DeletionConfirm> createState() => _DeletionConfirmState();
}

class _DeletionConfirmState extends State<DeletionConfirm> {
  final _typed = TextEditingController();

  @override
  void didUpdateWidget(DeletionConfirm oldWidget) {
    super.didUpdateWidget(oldWidget);
    // A changed plan clears the word — the controller forgets it too — so the
    // person confirms what they now see rather than what they saw.
    final planChanged = switch (widget.failure) {
      AccountDataFailure(problem: AccountDataProblem.deletionPlanChanged) =>
        true,
      _ => false,
    };
    if (planChanged && oldWidget.failure != widget.failure) _typed.clear();
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
          label: AccountDataCopy.deleteConfirmLabel,
          hint: AccountDataCopy.deleteConfirmHint,
          controller: _typed,
          enabled: !widget.isDeleting,
          textCapitalization: TextCapitalization.characters,
          textInputAction: TextInputAction.done,
          onChanged: widget.onTyped,
        ),
        const SizedBox(height: NestSpace.lg),
        NestButton(
          label: widget.isDeleting
              ? AccountDataCopy.deleteDeleting
              : AccountDataCopy.deleteButton,
          variant: NestButtonVariant.danger,
          icon: Icons.delete_forever_outlined,
          isLoading: widget.isDeleting,
          onPressed: widget.canDelete ? widget.onDelete : null,
        ),
      ],
    );
  }
}
