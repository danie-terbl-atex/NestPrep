import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../app/documents_route.dart';
import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../../accounts/ui/account_menu_button.dart';
import '../model/document_library.dart';
import '../state/document_library_controller.dart';
import 'document_folder_row.dart';
import 'document_folder_sheet.dart';

/// The household's filing cabinet: the folders, and how much is in each.
///
/// Reached from the Household screen rather than the bottom bar, which stays at
/// the four things a household does in a week (documents ADR-0001).
class DocumentLibraryScreen extends StatelessWidget {
  const DocumentLibraryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<DocumentLibraryController>();
    final failure = controller.actionFailure;
    return NestScaffold(
      title: AppCopy.documentsTitle,
      leading: context.canPop()
          ? NestIconButton(
              icon: Icons.arrow_back,
              label: AppCopy.back,
              variant: NestIconButtonVariant.plain,
              onPressed: context.pop,
            )
          : null,
      trailing: [
        if (controller.isAdmin)
          NestIconButton(
            icon: Icons.create_new_folder_outlined,
            label: AppCopy.documentsAddFolder,
            onPressed: () => _addFolder(context, controller),
          ),
        const AccountMenuButton(),
      ],
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (failure != null)
            Padding(
              padding: const EdgeInsets.only(bottom: NestSpace.lg),
              child: NestBanner(
                message: AppCopy.failure(failure),
                tone: NestBannerTone.danger,
                actionLabel: AppCopy.back,
                onAction: controller.dismissActionFailure,
              ),
            ),
          Expanded(
            child: NestAsyncView<DocumentLibrary>(
              state: controller.library,
              isEmpty: (library) => library.isEmpty,
              onRetry: controller.retry,
              emptyBuilder: (_) => NestEmptyView(
                title: AppCopy.documentsEmptyTitle,
                message: controller.isAdmin
                    ? AppCopy.documentsEmptyBody
                    : AppCopy.documentsEmptyBodyForMembers,
                icon: Icons.folder_outlined,
                actionLabel: controller.isAdmin
                    ? AppCopy.documentsAddFolder
                    : null,
                onAction: controller.isAdmin
                    ? () => _addFolder(context, controller)
                    : null,
              ),
              dataBuilder: (context, library) =>
                  _FolderList(library: library, controller: controller),
            ),
          ),
        ],
      ),
    );
  }

  static Future<void> _addFolder(
    BuildContext context,
    DocumentLibraryController controller,
  ) async {
    final result = await showDocumentFolderSheet(context: context);
    if (result == null || result.isDeleted) return;
    await controller.createFolder(result.name);
  }
}

class _FolderList extends StatelessWidget {
  const _FolderList({required this.library, required this.controller});

  final DocumentLibrary library;
  final DocumentLibraryController controller;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.only(bottom: NestSpace.huge),
      children: [
        Text(
          AppCopy.documentsOfflineNote,
          style: NestTheme.of(context).text.caption
              .copyWith(color: NestTheme.of(context).colors.inkTertiary),
        ),
        const SizedBox(height: NestSpace.lg),
        for (final folder in library.folders)
          Padding(
            padding: const EdgeInsets.only(bottom: NestSpace.sm),
            child: DocumentFolderRow(
              key: ValueKey(folder.id),
              folder: folder,
              count: library.countIn(folder.id),
              // Pushed, so back lands on the folder list rather than closing
              // the app (`FE-17`).
              onOpen: () => context.push(
                DocumentsRoute.folderPathFor(controller.householdId, folder.id),
              ),
              onEdit: controller.isAdmin
                  ? () => _editFolder(context, folder.id)
                  : null,
            ),
          ),
      ],
    );
  }

  Future<void> _editFolder(BuildContext context, String folderId) async {
    final folder = library.folderById(folderId);
    if (folder == null) return;
    final result = await showDocumentFolderSheet(
      context: context,
      existing: folder,
    );
    if (result == null) return;
    if (result.isDeleted) {
      await controller.deleteFolder(folder);
      return;
    }
    await controller.renameFolder(folder, result.name);
  }
}
