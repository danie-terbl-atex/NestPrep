import 'package:flutter/material.dart';

import '../tokens/nest_spacing.dart';
import '../tokens/nest_theme.dart';
import 'nest_brand_mark.dart';
import 'nest_button.dart';
import 'nest_icon_tile.dart';

/// The empty state: what this place is for and what to do next (`FE-08`).
///
/// With an [icon], a tile that says what belongs here. Without one, the mark,
/// for the places a new household meets empty on its first day.
class NestEmptyView extends StatelessWidget {
  const NestEmptyView({
    required this.title,
    required this.message,
    this.icon,
    this.actionLabel,
    this.onAction,
    super.key,
  });

  final String title;
  final String message;
  final IconData? icon;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    final label = actionLabel;
    final glyph = icon;
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
            if (glyph == null)
              const NestBrandMark()
            else
              NestIconTile(
                icon: glyph,
                tint: NestTileTint.lilac,
                size: NestSize.avatarLarge,
              ),
            const SizedBox(height: NestSpace.lg),
            Text(title, style: nest.text.headline, textAlign: TextAlign.center),
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
