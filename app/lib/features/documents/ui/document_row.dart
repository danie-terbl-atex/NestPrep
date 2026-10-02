import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/format/byte_size.dart';
import '../../../shared/time/calendar_date.dart';
import 'document_badges.dart';
import 'offline_badge.dart';

/// One document on a shelf — the household's or a vault's. Tapping opens it;
/// the subtitle says how big it is and who it concerns, and the badges say
/// when it expires and how it is tagged, which between them answer "is this
/// the one I want" without downloading anything.
class DocumentRow extends StatelessWidget {
  const DocumentRow({
    required this.name,
    required this.sizeBytes,
    required this.isImage,
    required this.onOpen,
    required this.today,
    this.byline,
    this.tags = const [],
    this.expiresOn,
    this.isKeptOffline = false,
    super.key,
  });

  final String name;
  final int sizeBytes;

  /// A picture or a PDF, for the tile — never the only signal (`FE-13`).
  final bool isImage;

  /// Who added it, or whose vault it is in — a name, never a colour alone.
  final String? byline;
  final List<String> tags;
  final CalendarDate? expiresOn;
  final CalendarDate today;
  final VoidCallback onOpen;

  /// Kept on this phone (documents ADR-0007) — known only while unlocked.
  final bool isKeptOffline;

  @override
  Widget build(BuildContext context) {
    return NestCard(
      variant: NestCardVariant.flat,
      padding: EdgeInsets.zero,
      child: NestListRow(
        title: name,
        subtitle: [NestBytes.format(sizeBytes), ?byline].join(' · '),
        leading: NestIconTile(
          icon: isImage ? LucideIcons.image : LucideIcons.fileText,
          tint: isImage ? NestTileTint.basil : NestTileTint.butter,
        ),
        onTap: onOpen,
        trailing: const Icon(LucideIcons.chevronRight),
        footer: _footer(),
      ),
    );
  }

  Widget? _footer() {
    final hasBadges = DocumentBadges.hasAny(expiresOn: expiresOn, tags: tags);
    if (!hasBadges && !isKeptOffline) return null;
    return Wrap(
      spacing: NestSpace.xs,
      runSpacing: NestSpace.xs,
      children: [
        if (isKeptOffline) const OfflineBadge(),
        if (hasBadges)
          DocumentBadges(expiresOn: expiresOn, tags: tags, today: today),
      ],
    );
  }
}
