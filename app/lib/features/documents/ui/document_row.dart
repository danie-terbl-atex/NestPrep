import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/format/byte_size.dart';
import '../../household/model/member.dart';
import '../model/household_document.dart';

/// One document on the shelf. Tapping opens it; the subtitle says who put it
/// there and how big it is, which between them answer "is this the one I
/// want" without downloading anything.
class DocumentRow extends StatelessWidget {
  const DocumentRow({
    required this.document,
    required this.uploadedBy,
    required this.onOpen,
    super.key,
  });

  final HouseholdDocument document;
  final Member? uploadedBy;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return NestCard(
      variant: NestCardVariant.flat,
      padding: EdgeInsets.zero,
      child: NestListRow(
        title: document.name,
        subtitle: _subtitle,
        leading: NestIconTile(
          icon: document.isPreviewable
              ? Icons.image_outlined
              : Icons.picture_as_pdf_outlined,
          tint: document.isPreviewable ? NestTileTint.mint : NestTileTint.peach,
        ),
        onTap: onOpen,
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }

  /// The size, and the person — a name, never a colour alone (`FE-13`).
  String get _subtitle {
    final by = uploadedBy;
    return [
      NestBytes.format(document.sizeBytes),
      if (by != null) by.displayName,
    ].join(' · ');
  }
}
