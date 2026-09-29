import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../app/documents_route.dart';
import '../../../design/nest_kit.dart';
import '../../../shared/time/household_clock.dart';
import '../model/document_entry.dart';
import '../model/document_library.dart';
import '../model/document_search.dart';
import '../state/document_library_controller.dart';
import 'document_sheet.dart';
import 'expiring_soon_card.dart';

/// The household papers that need renewing soon — the insurance, the licence
/// disc — at the top of the folders (documents ADR-0005). The vaults' own list
/// is on the vault home, behind the lock, because even a passport's name is
/// not shown on this side of it (documents ADR-0003).
class HouseholdExpiringSoon extends StatelessWidget {
  const HouseholdExpiringSoon({required this.library, super.key});

  final DocumentLibrary library;

  @override
  Widget build(BuildContext context) {
    final today = context.read<HouseholdClock>().today;
    final controller = context.read<DocumentLibraryController>();
    final soon = expiringSoon([
      for (final folder in library.folders)
        for (final document in library.inFolder(folder.id))
          HouseholdEntry(document, folderName: folder.name),
    ], today: today);
    if (soon.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: NestSpace.xl),
      child: NestRiseIn(
        child: ExpiringSoonCard(
          entries: soon,
          today: today,
          onOpen: (entry) {
            if (entry is! HouseholdEntry) return;
            showDocumentSheet(
              context: context,
              document: entry.document,
              folders: library.folders,
              canManage:
                  controller.isAdmin ||
                  entry.document.uploadedBy == controller.memberId,
            );
          },
          onSeeAll: () => context.push(
            DocumentsRoute.searchPathFor(
              controller.householdId,
              person: DocumentsRoute.householdPerson,
              expiringSoon: true,
            ),
          ),
        ),
      ),
    );
  }
}
