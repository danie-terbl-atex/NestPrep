import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';

/// The foot of the review list: the one button that adds anything, saying how
/// many it will add, and the way to another letter. It cannot be pressed
/// twice — it is busy while the events are being added (`FE-10`).
class LetterConfirmBar extends StatelessWidget {
  const LetterConfirmBar({
    required this.ticked,
    required this.hasItems,
    required this.isSaving,
    required this.onConfirm,
    required this.onStartOver,
    super.key,
  });

  final int ticked;
  final bool hasItems;
  final bool isSaving;
  final VoidCallback onConfirm;
  final VoidCallback onStartOver;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: NestSpace.sm, bottom: NestSpace.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (hasItems)
            NestButton(
              label: SchoolLetterCopy.addTicked(ticked),
              icon: LucideIcons.calendarCheck,
              isLoading: isSaving,
              onPressed: ticked == 0 || isSaving ? null : onConfirm,
            ),
          const SizedBox(height: NestSpace.xs),
          NestButton(
            label: SchoolLetterCopy.chooseAnother,
            variant: hasItems
                ? NestButtonVariant.ghost
                : NestButtonVariant.primary,
            icon: LucideIcons.scanText,
            onPressed: isSaving ? null : onStartOver,
          ),
        ],
      ),
    );
  }
}
