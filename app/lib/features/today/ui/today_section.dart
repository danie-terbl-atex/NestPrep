import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';

/// One block of the Today tab: an eyebrow, what it holds, and the door into
/// the tab that owns it.
class TodaySection extends StatelessWidget {
  const TodaySection({
    required this.eyebrow,
    required this.child,
    this.actionLabel,
    this.onAction,
    super.key,
  });

  final String eyebrow;
  final Widget child;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final label = actionLabel;
    return Padding(
      padding: const EdgeInsets.only(bottom: NestSpace.xxl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(child: NestEyebrow(eyebrow)),
              if (label != null)
                Flexible(
                  child: NestButton(
                    label: label,
                    icon: LucideIcons.arrowRight,
                    onPressed: onAction,
                    variant: NestButtonVariant.ghost,
                    size: NestButtonSize.small,
                    isExpanded: false,
                  ),
                ),
            ],
          ),
          const SizedBox(height: NestSpace.sm),
          child,
        ],
      ),
    );
  }
}
