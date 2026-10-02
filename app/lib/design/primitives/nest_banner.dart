import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../tokens/nest_spacing.dart';
import '../tokens/nest_theme.dart';
import 'nest_button.dart';

enum NestBannerTone { info, success, warning, danger }

/// An inline notice with an optional action: a failed send, an offline hint.
/// Never the raw error — the screen passes copy from `AppCopy` (`FE-09`).
class NestBanner extends StatelessWidget {
  const NestBanner({
    required this.message,
    this.tone = NestBannerTone.info,
    this.actionLabel,
    this.onAction,
    super.key,
  });

  final String message;
  final NestBannerTone tone;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    final c = nest.colors;
    final (fill, ink, icon) = switch (tone) {
      NestBannerTone.info => (c.accentSoft, c.accentInk, LucideIcons.info),
      NestBannerTone.success => (
        c.successSoft,
        c.success,
        LucideIcons.circleCheck,
      ),
      NestBannerTone.warning => (
        c.warningSoft,
        c.warning,
        LucideIcons.triangleAlert,
      ),
      NestBannerTone.danger => (
        c.dangerSoft,
        c.danger,
        LucideIcons.circleAlert,
      ),
    };
    final label = actionLabel;
    return Semantics(
      liveRegion: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: fill,
          borderRadius: BorderRadius.circular(NestRadius.lg),
        ),
        child: Padding(
          padding: const EdgeInsets.all(NestSpace.lg),
          child: Row(
            children: [
              Icon(icon, color: ink, size: NestSize.iconMedium),
              const SizedBox(width: NestSpace.md),
              Expanded(
                child: Text(
                  message,
                  style: nest.text.body.copyWith(color: ink),
                ),
              ),
              if (label != null) ...[
                const SizedBox(width: NestSpace.md),
                NestButton(
                  label: label,
                  onPressed: onAction,
                  variant: NestButtonVariant.ghost,
                  size: NestButtonSize.small,
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
