import 'package:flutter/material.dart';

import '../tokens/nest_spacing.dart';
import '../tokens/nest_theme.dart';
import 'nest_icon_button.dart';

/// "Today's plan  +": a section title with an optional action in the corner.
class NestSectionHeader extends StatelessWidget {
  const NestSectionHeader({
    required this.title,
    this.actionIcon,
    this.actionLabel,
    this.onAction,
    super.key,
  });

  final String title;
  final IconData? actionIcon;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    final icon = actionIcon;
    return Padding(
      padding: const EdgeInsets.only(left: NestSpace.xs),
      child: Row(
        children: [
          Expanded(child: Text(title, style: nest.text.screenTitle)),
          if (icon != null)
            NestIconButton(
              icon: icon,
              label: actionLabel ?? title,
              onPressed: onAction,
              variant: NestIconButtonVariant.plain,
            ),
        ],
      ),
    );
  }
}
