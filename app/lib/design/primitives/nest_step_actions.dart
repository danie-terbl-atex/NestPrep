import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../tokens/nest_spacing.dart';
import 'nest_button.dart';

/// The foot of a step in a guided flow: the way on, an optional second way
/// on beside it, and the way back. The way on is null while the step is not
/// ready and shows its work while [isBusy]. The second way and the way back
/// show only when they have both a label and a callback, so a flow hides
/// them while it writes. Every word is the caller's (`FE-19`).
class NestStepActions extends StatelessWidget {
  const NestStepActions({
    required this.nextLabel,
    required this.nextIcon,
    required this.onNext,
    this.nextKey,
    this.isBusy = false,
    this.secondaryLabel,
    this.onSecondary,
    this.secondaryKey,
    this.backLabel,
    this.onBack,
    super.key,
  });

  final String nextLabel;
  final IconData nextIcon;
  final VoidCallback? onNext;
  final Key? nextKey;
  final bool isBusy;
  final String? secondaryLabel;
  final VoidCallback? onSecondary;
  final Key? secondaryKey;
  final String? backLabel;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final secondaryLabel = this.secondaryLabel;
    final onSecondary = this.onSecondary;
    final backLabel = this.backLabel;
    final onBack = this.onBack;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        NestButton(
          key: nextKey,
          label: nextLabel,
          icon: nextIcon,
          isLoading: isBusy,
          onPressed: onNext,
        ),
        if (secondaryLabel != null && onSecondary != null) ...[
          const SizedBox(height: NestSpace.xs),
          NestButton(
            key: secondaryKey,
            label: secondaryLabel,
            variant: NestButtonVariant.outline,
            size: NestButtonSize.small,
            onPressed: onSecondary,
          ),
        ],
        if (backLabel != null && onBack != null) ...[
          const SizedBox(height: NestSpace.xs),
          NestButton(
            label: backLabel,
            icon: LucideIcons.arrowLeft,
            variant: NestButtonVariant.ghost,
            size: NestButtonSize.small,
            onPressed: onBack,
          ),
        ],
      ],
    );
  }
}
