import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/vault_copy.dart';
import '../../../shared/time/household_clock.dart';
import '../model/document_entry.dart';
import '../model/document_limits.dart';
import '../state/document_library_controller.dart';
import 'document_row.dart';
import 'document_sheet.dart';
import 'vault_document_sheet.dart';

/// What a search found, each opened the way its kind is opened: a household
/// document directly, a vault document through the logged callable (documents
/// ADR-0003). Nothing found says so, with the way out.
class DocumentSearchResults extends StatelessWidget {
  const DocumentSearchResults({
    required this.results,
    required this.ownerNames,
    required this.onClearFilters,
    this.header,
    super.key,
  });

  final List<DocumentEntry> results;
  final Map<String, String> ownerNames;
  final VoidCallback onClearFilters;

  /// Said above the results — that the vaults were not searched, say.
  final Widget? header;

  @override
  Widget build(BuildContext context) {
    final top = header;
    if (results.isEmpty) {
      final empty = NestEmptyView(
        title: VaultCopy.searchNoResultsTitle,
        message: VaultCopy.searchNoResultsBody,
        icon: Icons.search_off,
        actionLabel: VaultCopy.searchClearFilters,
        onAction: onClearFilters,
      );
      if (top == null) return empty;
      // The way to unlock stays above "nothing matches" — the match may be in
      // a vault (`FE-08`).
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          top,
          Expanded(child: empty),
        ],
      );
    }
    final nest = NestTheme.of(context);
    final today = context.read<HouseholdClock>().today;
    // Built lazily: a household can hold a few hundred papers (`FE-11`).
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: NestSpace.huge),
      itemCount: results.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: NestSpace.sm),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (top != null) ...[top, const SizedBox(height: NestSpace.md)],
                Text(
                  VaultCopy.resultCount(results.length),
                  style: nest.text.caption.copyWith(
                    color: nest.colors.inkTertiary,
                  ),
                ),
              ],
            ),
          );
        }
        final entry = results[index - 1];
        return Padding(
          key: ValueKey('${entry.ownerMemberId}/${entry.id}'),
          padding: const EdgeInsets.only(bottom: NestSpace.sm),
          child: DocumentRow(
            name: entry.name,
            sizeBytes: entry.sizeBytes,
            isImage: DocumentLimits.isPreviewable(entry.contentType),
            byline: switch (entry) {
              HouseholdEntry(:final folderName) => folderName,
              VaultEntry(:final ownerMemberId) => VaultCopy.vaultOf(
                ownerNames[ownerMemberId] ?? '',
              ),
            },
            tags: entry.tags,
            expiresOn: entry.expiresOn,
            today: today,
            onOpen: () => _open(context, entry),
          ),
        );
      },
    );
  }

  static void _open(BuildContext context, DocumentEntry entry) {
    switch (entry) {
      case VaultEntry(:final document):
        showVaultDocumentSheet(context: context, document: document);
      case HouseholdEntry(:final document):
        final controller = context.read<DocumentLibraryController>();
        final library = controller.loadedLibrary;
        showDocumentSheet(
          context: context,
          document: document,
          folders: library?.folders ?? const [],
          canManage:
              controller.isAdmin || document.uploadedBy == controller.memberId,
        );
    }
  }
}
