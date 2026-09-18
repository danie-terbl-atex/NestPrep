import 'package:flutter/material.dart';

import '../tokens/nest_spacing.dart';
import '../tokens/nest_theme.dart';
import 'nest_button.dart';
import 'nest_icon_tile.dart';

/// The empty state: what this place is for and what to do next (`FE-08`).
class NestEmptyView extends StatelessWidget {
  const NestEmptyView({
    required this.title,
    required this.message,
    this.icon = Icons.auto_awesome_outlined,
    this.actionLabel,
    this.onAction,
    super.key,
  });

  final String title;
  final String message;
  final IconData icon;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    final label = actionLabel;
    // Centred when there is room and scrollable when there is not. An empty
    // state is the one surface with no content to push things off the edge, so
    // an overflow here is always the *frame* being short — a small phone, a
    // landscape keyboard, 200% text, or a screen that grew a row above it. It
    // adapts rather than showing the stripes (`FE-08`, `FE-14`).
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(NestSpace.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            NestIconTile(icon: icon, size: NestSize.avatarLarge),
            const SizedBox(height: NestSpace.lg),
            Text(title, style: nest.text.title, textAlign: TextAlign.center),
            const SizedBox(height: NestSpace.sm),
            Text(
              message,
              style: nest.text.bodySecondary,
              textAlign: TextAlign.center,
            ),
            if (label != null) ...[
              const SizedBox(height: NestSpace.xxl),
              NestButton(
                label: label,
                onPressed: onAction,
                variant: NestButtonVariant.tonal,
                size: NestButtonSize.medium,
                isExpanded: false,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
