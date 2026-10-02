import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';

/// The foot of a step: the way on, and the way back. The way on is null
/// while the step is not ready, and shows its work while it is busy.
class PlanWeekStepActions extends StatelessWidget {
  const PlanWeekStepActions({
    required this.label,
    required this.icon,
    required this.onNext,
    this.onBack,
    this.isBusy = false,
    this.nextKey,
    super.key,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onNext;
  final VoidCallback? onBack;
  final bool isBusy;
  final Key? nextKey;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      NestButton(
        key: nextKey,
        label: label,
        icon: icon,
        isLoading: isBusy,
        onPressed: onNext,
      ),
      if (onBack case final onBack?) ...[
        const SizedBox(height: NestSpace.xs),
        NestButton(
          label: PlanWeekCopy.back,
          icon: Icons.arrow_back_rounded,
          variant: NestButtonVariant.ghost,
          size: NestButtonSize.small,
          onPressed: onBack,
        ),
      ],
    ],
  );
}
