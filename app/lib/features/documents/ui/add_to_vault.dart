import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import '../../../shared/copy/vault_copy.dart';
import '../../../shared/format/nest_dates.dart';
import '../../../shared/time/household_clock.dart';
import '../model/document_tags.dart';
import '../model/vault_upload_details.dart';
import '../state/vault_controller.dart';
import 'document_details_sheet.dart';
import 'document_source_sheet.dart';

/// Adding to somebody's vault: scan the two sides of a card, or choose a file,
/// then name it, tag it and date it before anything is uploaded (documents
/// ADR-0004, ADR-0005). Backing out at any step adds nothing and says nothing.
Future<void> addToVault(BuildContext context, String ownerMemberId) async {
  final controller = context.read<VaultController>();
  final today = context.read<HouseholdClock>().today;
  final suggestions = DocumentTags.vocabulary(
    controller.loadedShelf?.everyDocument.map((doc) => doc.tags) ?? const [],
  );
  final source = await showDocumentSourceSheet(context);
  if (source == null || !context.mounted) return;

  switch (source) {
    case DocumentSource.scan:
      final sides = await controller.scan();
      if (sides == null || !context.mounted) return;
      final details = await showDocumentDetailsSheet(
        context: context,
        title: VaultCopy.reviewTitle,
        saveLabel: VaultCopy.saveToVault,
        today: today,
        initialName: VaultCopy.scanName(NestDates.full(today, today)),
        sides: sides,
        tagSuggestions: suggestions,
      );
      if (details == null) return;
      await controller.addScan(sides, _detailsFor(ownerMemberId, details));
    case DocumentSource.file:
      final file = await controller.pickFile();
      if (file == null || !context.mounted) return;
      final details = await showDocumentDetailsSheet(
        context: context,
        title: VaultCopy.addOptionsTitle,
        saveLabel: VaultCopy.saveToVault,
        today: today,
        initialName: file.name,
        tagSuggestions: suggestions,
      );
      if (details == null) return;
      await controller.addFile(file, _detailsFor(ownerMemberId, details));
  }
}

VaultUploadDetails _detailsFor(String ownerMemberId, DocumentDetails details) =>
    VaultUploadDetails(
      ownerMemberId: ownerMemberId,
      name: details.name,
      tags: details.tags,
      expiresOn: details.expiresOn,
    );
