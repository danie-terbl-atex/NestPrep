import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';

/// The privacy boundary, in plain words (household ADR-0004): what the other
/// home sees, and what stays in this one. Shown before a code is made, before
/// one is accepted, and from every link — the same two lists each time, so a
/// parent reads one promise, not three.
class PrivacyBoundary extends StatelessWidget {
  const PrivacyBoundary({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _List(
          heading: TwoHomesSetupCopy.sharedHeading,
          items: TwoHomesSetupCopy.sharedItems,
          icon: Icons.swap_horiz,
          tone: NestTagTone.accent,
        ),
        const SizedBox(height: NestSpace.lg),
        const _List(
          heading: TwoHomesSetupCopy.privateHeading,
          items: TwoHomesSetupCopy.privateItems,
          icon: Icons.lock_outline,
          tone: NestTagTone.success,
        ),
        const SizedBox(height: NestSpace.lg),
        Text(
          TwoHomesSetupCopy.privacyFooter,
          style: NestTheme.of(context).text.caption
              .copyWith(color: NestTheme.of(context).colors.inkTertiary),
        ),
      ],
    );
  }
}

class _List extends StatelessWidget {
  const _List({
    required this.heading,
    required this.items,
    required this.icon,
    required this.tone,
  });

  final String heading;
  final List<String> items;
  final IconData icon;
  final NestTagTone tone;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    return NestCard(
      variant: NestCardVariant.flat,
      padding: const EdgeInsets.all(NestSpace.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          NestTag(label: heading, tone: tone, icon: icon),
          const SizedBox(height: NestSpace.md),
          for (final item in items)
            Padding(
              padding: const EdgeInsets.only(bottom: NestSpace.sm),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: NestSpace.xxs),
                    child: Icon(
                      icon == Icons.lock_outline ? Icons.check : Icons.east,
                      size: NestSize.iconSmall,
                      color: nest.colors.inkTertiary,
                    ),
                  ),
                  const SizedBox(width: NestSpace.sm),
                  Expanded(
                    child: Text(
                      item,
                      style: nest.text.body.copyWith(color: nest.colors.ink),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
