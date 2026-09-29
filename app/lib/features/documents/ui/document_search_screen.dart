import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/async/async_state.dart';
import '../../../shared/copy/app_copy.dart';
import '../../../shared/copy/vault_copy.dart';
import '../../../shared/time/household_clock.dart';
import '../../household/model/household_view.dart';
import '../model/document_entry.dart';
import '../model/document_library.dart';
import '../model/document_search.dart';
import '../model/document_tags.dart';
import '../state/document_library_controller.dart';
import '../state/document_search_controller.dart';
import '../state/vault_controller.dart';
import '../state/vault_lock_controller.dart';
import 'document_search_filters.dart';
import 'document_search_results.dart';
import 'vault_locked_note.dart';

/// Finding a paper by name, person or tag, across the household's folders
/// and — while they are unlocked — the personal vaults (documents ADR-0005).
///
/// Everything searched is already in memory from bounded listeners, so typing
/// filters instantly and asks the server nothing. A locked vault is not
/// searched at all, and the screen says so rather than pretending there is
/// nothing in it.
class DocumentSearchScreen extends StatelessWidget {
  const DocumentSearchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final search = context.watch<DocumentSearchController>();
    final library = context.watch<DocumentLibraryController>().library;
    final vault = context.watch<VaultController>();
    final lock = context.watch<VaultLockController>();
    final shelf = lock.isUnlocked ? vault.loadedShelf : null;
    return NestScaffold(
      title: VaultCopy.searchTitle,
      leading: context.canPop()
          ? NestIconButton(
              icon: Icons.arrow_back,
              label: AppCopy.back,
              variant: NestIconButtonVariant.plain,
              onPressed: context.pop,
            )
          : null,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          NestTextField(
            label: VaultCopy.searchTitle,
            hint: VaultCopy.searchHint,
            prefixIcon: Icons.search,
            autofocus: search.query.isEmpty,
            textInputAction: TextInputAction.search,
            onChanged: search.setText,
          ),
          const SizedBox(height: NestSpace.md),
          DocumentSearchFilters(
            query: search.query,
            owners: shelf?.owners ?? const [],
            tags: DocumentTags.vocabulary([
              ..._entriesOf(library).map((entry) => entry.tags),
              ...?shelf?.everyDocument.map((doc) => doc.tags),
            ]),
            onOwner: search.setOwner,
            onTag: search.toggleTag,
            onExpiringSoon: search.setExpiringSoonOnly,
          ),
          const SizedBox(height: NestSpace.md),
          Expanded(
            child: NestAsyncView<DocumentLibrary>(
              state: library,
              isEmpty: (_) => false,
              onRetry: context.read<DocumentLibraryController>().retry,
              emptyBuilder: (_) => const SizedBox.shrink(),
              dataBuilder: (context, value) {
                final names = {
                  for (final member in context.read<HouseholdView>().members)
                    member.id: member.displayName,
                };
                final found = searchDocuments(
                  [
                    ..._entriesOf(library),
                    ...?shelf?.everyDocument.map(VaultEntry.new),
                  ],
                  search.query,
                  today: context.read<HouseholdClock>().today,
                  ownerNames: names,
                );
                return DocumentSearchResults(
                  results: found,
                  ownerNames: names,
                  onClearFilters: search.clear,
                  header: lock.isUnlocked
                      ? null
                      : VaultLockedNote(onUnlock: lock.unlock),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  static List<DocumentEntry> _entriesOf(AsyncState<DocumentLibrary> state) =>
      switch (state) {
        AsyncData(:final value) => [
          for (final folder in value.folders)
            for (final document in value.inFolder(folder.id))
              HouseholdEntry(document, folderName: folder.name),
        ],
        _ => const [],
      };
}
