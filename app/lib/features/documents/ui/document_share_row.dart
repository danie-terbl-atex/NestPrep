import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';

/// One live link on the Shared links screen (documents ADR-0006): which
/// document, until when, whether it asks for a PIN, how often it was opened
/// and when last, who shared it — and the button that stops it. Every fact is
/// words and an icon, never a colour alone (`FE-13`).
class DocumentShareRow extends StatelessWidget {
  const DocumentShareRow({
    required this.documentName,
    required this.endsLabel,
    required this.openedLabel,
    required this.hasPin,
    required this.isFromVault,
    required this.isStopping,
    required this.onStop,
    this.sharedBy,
    super.key,
  });

  final String documentName;

  /// "Works until Today, 18:00", or "Works until the shift ends".
  final String endsLabel;

  /// "Opened twice · last Today, 14:02", or "Not opened yet".
  final String openedLabel;
  final bool hasPin;
  final bool isFromVault;
  final bool isStopping;

  /// Who made it, for the family reading everybody's links.
  final String? sharedBy;
  final VoidCallback onStop;

  @override
  Widget build(BuildContext context) {
    return NestCard(
      variant: NestCardVariant.flat,
      padding: EdgeInsets.zero,
      child: NestListRow(
        title: documentName,
        subtitle: [endsLabel, openedLabel, ?sharedBy].join(' · '),
        leading: const NestIconTile(icon: Icons.link, tint: NestTileTint.lilac),
        footer: hasPin || isFromVault
            ? Wrap(
                spacing: NestSpace.xs,
                runSpacing: NestSpace.xs,
                children: [
                  if (hasPin)
                    const NestTag(
                      label: ShareLinkCopy.withPin,
                      icon: Icons.pin_outlined,
                      tone: NestTagTone.accent,
                    ),
                  if (isFromVault)
                    const NestTag(
                      label: ShareLinkCopy.fromVault,
                      icon: Icons.lock_outline,
                    ),
                ],
              )
            : null,
        trailing: NestIconButton(
          icon: Icons.link_off,
          label: ShareLinkCopy.stopLabel(documentName),
          variant: NestIconButtonVariant.plain,
          onPressed: isStopping ? null : onStop,
        ),
      ),
    );
  }
}
