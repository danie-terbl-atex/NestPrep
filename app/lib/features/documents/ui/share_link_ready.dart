import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../model/shared_link.dart';

/// The link, once — with the two ways to get it to somebody, when it stops
/// working, and a reminder to send any PIN on its own (documents ADR-0006).
/// NestPrep never shows it again, so this says so.
class ShareLinkReady extends StatelessWidget {
  const ShareLinkReady({
    required this.link,
    required this.endsLabel,
    required this.hasPin,
    required this.onSend,
    required this.onCopy,
    required this.onDone,
    super.key,
  });

  final SharedLink link;
  final String endsLabel;
  final bool hasPin;
  final VoidCallback onSend;
  final VoidCallback onCopy;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        const NestRiseIn(
          child: Center(
            child: NestIconTile(
              icon: LucideIcons.link,
              tint: NestTileTint.basil,
            ),
          ),
        ),
        const SizedBox(height: NestSpace.md),
        Text(
          ShareLinkCopy.readyTitle,
          textAlign: TextAlign.center,
          style: nest.text.title,
        ),
        const SizedBox(height: NestSpace.xs),
        Text(
          ShareLinkCopy.readyBody,
          textAlign: TextAlign.center,
          style: nest.text.bodySecondary,
        ),
        const SizedBox(height: NestSpace.lg),
        NestCard(
          variant: NestCardVariant.tinted,
          child: SelectableText(
            link.url.toString(),
            style: nest.text.caption.copyWith(color: nest.colors.ink),
          ),
        ),
        const SizedBox(height: NestSpace.sm),
        Wrap(
          spacing: NestSpace.sm,
          runSpacing: NestSpace.sm,
          children: [
            NestTag(label: endsLabel, icon: LucideIcons.clock),
            if (hasPin)
              const NestTag(
                label: ShareLinkCopy.withPin,
                icon: LucideIcons.rectangleEllipsis,
                tone: NestTagTone.accent,
              ),
          ],
        ),
        if (hasPin) ...[
          const SizedBox(height: NestSpace.md),
          const NestBanner(message: ShareLinkCopy.withPinReminder),
        ],
        const SizedBox(height: NestSpace.xl),
        NestButton(
          label: ShareLinkCopy.send,
          icon: LucideIcons.share,
          onPressed: onSend,
        ),
        const SizedBox(height: NestSpace.sm),
        NestButton(
          label: ShareLinkCopy.copy,
          icon: LucideIcons.copy,
          variant: NestButtonVariant.tonal,
          onPressed: onCopy,
        ),
        const SizedBox(height: NestSpace.sm),
        NestButton(
          label: ShareLinkCopy.done,
          variant: NestButtonVariant.ghost,
          onPressed: onDone,
        ),
      ],
    );
  }
}
