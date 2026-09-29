import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import '../../../shared/copy/vault_copy.dart';
import '../../../shared/format/nest_dates.dart';
import '../../../shared/time/household_clock.dart';
import '../state/document_library_controller.dart';
import 'document_details_sheet.dart';
import 'document_source_sheet.dart';

/// Adding to a household folder: scan it, or choose a file (documents
/// ADR-0004). A scan is shown back to check and name before it is filed;
/// tags and an expiry are set afterwards on the document itself, where
/// everybody who can change it can.
Future<void> addToFolder(BuildContext context, String folderId) async {
  final controller = context.read<DocumentLibraryController>();
  final today = context.read<HouseholdClock>().today;
  final source = await showDocumentSourceSheet(context);
  if (source == null || !context.mounted) return;

  switch (source) {
    case DocumentSource.file:
      await controller.addDocument(folderId);
    case DocumentSource.scan:
      final sides = await controller.scanSides();
      if (sides == null || !context.mounted) return;
      final details = await showDocumentDetailsSheet(
        context: context,
        title: VaultCopy.reviewTitle,
        saveLabel: VaultCopy.saveToFolder,
        today: today,
        initialName: VaultCopy.scanName(NestDates.full(today, today)),
        sides: sides,
        withTagsAndExpiry: false,
      );
      if (details == null) return;
      await controller.addScan(folderId, pages: sides, name: details.name);
  }
}
