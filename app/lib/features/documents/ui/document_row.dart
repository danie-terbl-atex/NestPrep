import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/format/byte_size.dart';
import '../../../shared/time/calendar_date.dart';
import 'document_badges.dart';

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

  @override
  Widget build(BuildContext context) {
    return NestCard(
      variant: NestCardVariant.flat,
      padding: EdgeInsets.zero,
      child: NestListRow(
        title: name,
        subtitle: [NestBytes.format(sizeBytes), ?byline].join(' · '),
        leading: NestIconTile(
          icon: isImage ? Icons.image_outlined : Icons.picture_as_pdf_outlined,
          tint: isImage ? NestTileTint.mint : NestTileTint.peach,
        ),
        onTap: onOpen,
        trailing: const Icon(Icons.chevron_right),
        footer: DocumentBadges.hasAny(expiresOn: expiresOn, tags: tags)
            ? DocumentBadges(expiresOn: expiresOn, tags: tags, today: today)
            : null,
      ),
    );
  }
}
