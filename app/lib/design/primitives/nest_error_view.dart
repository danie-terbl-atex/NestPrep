import 'package:flutter/material.dart';

import '../tokens/nest_spacing.dart';
import '../tokens/nest_theme.dart';
import 'nest_button.dart';
import 'nest_icon_tile.dart';

/// The error state: human copy and a retry, never the raw error (`FE-09`).
class NestErrorView extends StatelessWidget {
  const NestErrorView({
    required this.message,
    required this.retryLabel,
    required this.onRetry,
    this.title,
    super.key,
  });

  final String message;
  final String retryLabel;
  final VoidCallback onRetry;
  final String? title;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    final titleText = title;
    // Centred when there is room and scrollable when there is not, like the
    // empty state and for the same reason: a failure has no content to push
    // anything off the edge, so an overflow here is the frame being short — a
    // screen that grew a row above it, or 200% text (`FE-08`, `FE-14`).
    return Center(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(NestSpace.xxl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const NestIconTile(
                icon: Icons.cloud_off_outlined,
                tint: NestTileTint.peach,
                size: NestSize.avatarLarge,
              ),
              const SizedBox(height: NestSpace.lg),
              if (titleText != null) ...[
                Text(
                  titleText,
                  style: nest.text.title,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: NestSpace.sm),
              ],
              Text(
                message,
                style: nest.text.bodySecondary,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: NestSpace.xxl),
              NestButton(
                label: retryLabel,
                onPressed: onRetry,
                variant: NestButtonVariant.outline,
                size: NestButtonSize.medium,
                isExpanded: false,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
