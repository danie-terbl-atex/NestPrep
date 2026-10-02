import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../tokens/nest_spacing.dart';
import '../tokens/nest_theme.dart';
import 'nest_button.dart';
import 'nest_icon_tile.dart';

/// The error state: human copy and a retry, never the raw error (`FE-09`).
///
/// A second way out — [secondaryLabel] and [onSecondary], given together — is
/// for the one screen where retrying may never work and there is nowhere else
/// to go, like the session gate's *Sign out*.
class NestErrorView extends StatelessWidget {
  const NestErrorView({
    required this.message,
    required this.retryLabel,
    required this.onRetry,
    this.title,
    this.secondaryLabel,
    this.onSecondary,
    super.key,
  }) : assert(
         (secondaryLabel == null) == (onSecondary == null),
         'A second action needs both a label and a callback.',
       );

  final String message;
  final String retryLabel;
  final VoidCallback onRetry;
  final String? title;
  final String? secondaryLabel;
  final VoidCallback? onSecondary;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    final titleText = title;
    final secondaryText = secondaryLabel;
    final secondaryPressed = onSecondary;
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
                icon: LucideIcons.cloudOff,
                tint: NestTileTint.butter,
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
              if (secondaryText != null && secondaryPressed != null) ...[
                const SizedBox(height: NestSpace.sm),
                NestButton(
                  label: secondaryText,
                  onPressed: secondaryPressed,
                  variant: NestButtonVariant.ghost,
                  size: NestButtonSize.medium,
                  isExpanded: false,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
