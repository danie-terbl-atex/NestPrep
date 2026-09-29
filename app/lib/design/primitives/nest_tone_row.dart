import 'package:flutter/material.dart';

import '../tokens/nest_spacing.dart';
import '../tokens/nest_theme.dart';
import 'nest_tag.dart';

/// A row that has to be noticed before it is read: an icon, a title, an
/// optional line under it, painted in a tone — a severe allergy in the danger
/// pair, a moderate one in the warning pair.
///
/// Where `NestBanner` is a message about the screen, this is one item in a
/// list that carries its own seriousness. The tone is never the only signal:
/// the icon and whatever the caller puts in [trailing] (a `NestTag` naming the
/// severity) say it too (`FE-13`).
class NestToneRow extends StatelessWidget {
  const NestToneRow({
    required this.icon,
    required this.title,
    this.subtitle,
    this.tone = NestTagTone.neutral,
    this.trailing,
    this.onTap,
    super.key,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final NestTagTone tone;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    final c = nest.colors;
    final (fill, ink) = switch (tone) {
      NestTagTone.neutral => (c.surfaceTint, c.accentInk),
      NestTagTone.accent => (c.accentSoft, c.accentInk),
      NestTagTone.success => (c.successSoft, c.success),
      NestTagTone.warning => (c.warningSoft, c.warning),
      NestTagTone.danger => (c.dangerSoft, c.danger),
    };
    final line = subtitle;
    final end = trailing;
    return Material(
      color: fill,
      borderRadius: BorderRadius.circular(NestRadius.lg),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: NestSize.controlLarge),
          child: Padding(
            padding: const EdgeInsets.all(NestSpace.md),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: NestSpace.xxs),
                  child: Icon(icon, color: ink, size: NestSize.iconMedium),
                ),
                const SizedBox(width: NestSpace.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(title, style: nest.text.bodyStrong),
                      if (line != null) ...[
                        const SizedBox(height: NestSpace.xxs),
                        Text(line, style: nest.text.caption),
                      ],
                    ],
                  ),
                ),
                if (end != null) ...[const SizedBox(width: NestSpace.sm), end],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
