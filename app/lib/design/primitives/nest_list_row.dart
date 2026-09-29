import 'package:flutter/material.dart';

import '../tokens/nest_motion.dart';
import '../tokens/nest_spacing.dart';
import '../tokens/nest_theme.dart';

/// A row in a list: a leading tile or avatar, a title, an optional subtitle
/// and trailing. Selected paints the tonal fill. Tapping is the row's only
/// behaviour; what happens next is the screen's decision (`FE-17`).
class NestListRow extends StatelessWidget {
  const NestListRow({
    required this.title,
    this.subtitle,
    this.leading,
    this.trailing,
    this.onTap,
    this.isSelected = false,
    this.titleStyle,
    this.footer,
    super.key,
  });

  final String title;
  final String? subtitle;
  final Widget? leading;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool isSelected;

  /// Override for the light, large list title of a schedule row.
  final TextStyle? titleStyle;

  /// Anything under the subtitle — a row of badges, say. It sits inside the
  /// row's own box, so the row still owns its layout (`FE-03`).
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    final c = nest.colors;
    final subtitleText = subtitle;
    return AnimatedContainer(
      duration: NestMotion.of(context).quick,
      decoration: BoxDecoration(
        color: isSelected ? c.surfaceTint : Colors.transparent,
        borderRadius: BorderRadius.circular(NestRadius.lg),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(NestRadius.lg),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: NestSize.controlLarge),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: NestSpace.lg,
                vertical: NestSpace.md,
              ),
              child: Row(
                children: [
                  if (leading != null) ...[
                    leading!,
                    const SizedBox(width: NestSpace.lg),
                  ],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(title, style: titleStyle ?? nest.text.bodyStrong),
                        if (subtitleText != null) ...[
                          const SizedBox(height: NestSpace.xxs),
                          Text(subtitleText, style: nest.text.caption),
                        ],
                        if (footer != null) ...[
                          const SizedBox(height: NestSpace.sm),
                          footer!,
                        ],
                      ],
                    ),
                  ),
                  if (trailing != null) ...[
                    const SizedBox(width: NestSpace.md),
                    trailing!,
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
