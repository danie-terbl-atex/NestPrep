import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/async/async_state.dart';
import '../../../shared/copy/app_copy.dart';
import '../../../shared/copy/vault_copy.dart';
import '../../../shared/failure/app_failure.dart';
import '../../../shared/time/household_clock.dart';
import '../../accounts/ui/account_menu_button.dart';
import '../../household/model/household_area.dart';
import '../../household/model/household_view.dart';
import '../model/document_library.dart';
import '../model/document_tags.dart';
import '../state/document_library_controller.dart';
import '../state/offline_copies_controller.dart';
import 'add_to_folder.dart';
import 'document_row.dart';
import 'document_sheet.dart';
import 'document_upload_card.dart';

/// What is filed in one folder. The add control lives in the header, outside
/// the view that gets swapped for the empty state — otherwise the first person
/// to open an empty folder has no way to fill it (`FE-08`, and the vault lesson
/// on exactly that).
class DocumentFolderScreen extends StatelessWidget {
  const DocumentFolderScreen({required this.folderId, super.key});

  final String folderId;

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<DocumentLibraryController>();
    final failure = controller.actionFailure;
    final library = switch (controller.library) {
      AsyncData(:final value) => value,
      _ => null,
    };
    final folder = library?.folderById(folderId);
    // A helper granted documents at view reads them and adds nothing
    // (household ADR-0003); the rules refuse the upload either way.
    final canEdit = context.watch<HouseholdView>().permissions.canEdit(
      HouseholdArea.documents,
    );

    return NestScaffold(
      title: folder?.name ?? AppCopy.documentsFolderFallbackTitle,
      leading: context.canPop()
          ? NestIconButton(
              icon: Icons.arrow_back,
              label: AppCopy.back,
              variant: NestIconButtonVariant.plain,
              onPressed: context.pop,
            )
          : null,
      trailing: [
        if (canEdit)
          NestIconButton(
            icon: Icons.upload_file_outlined,
            label: AppCopy.documentsAdd,
            variant: NestIconButtonVariant.accent,
            onPressed: controller.upload != null
                ? null
                : () => addToFolder(context, folderId),
          ),
        const AccountMenuButton(),
      ],
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (failure != null)
            Padding(
              padding: const EdgeInsets.only(bottom: NestSpace.md),
              child: NestBanner(
                message: AppCopy.failure(failure),
                tone: NestBannerTone.danger,
                actionLabel: AppCopy.back,
                onAction: controller.dismissActionFailure,
              ),
            ),
          if (controller.isPreparing)
            const Padding(
              padding: EdgeInsets.only(bottom: NestSpace.md),
              child: NestBanner(message: VaultCopy.preparing),
            ),
          if (controller.upload != null || controller.canRetryUpload)
            Padding(
              padding: const EdgeInsets.only(bottom: NestSpace.md),
              child: DocumentUploadCard(
                upload: controller.upload,
                canRetry: controller.canRetryUpload,
                onCancel: controller.cancelUpload,
                onRetry: controller.retryUpload,
                onDismiss: controller.forgetUpload,
              ),
            ),
          Expanded(
            child: NestAsyncView<DocumentLibrary>(
              state: controller.library,
              isEmpty: (value) =>
                  value.folderById(folderId) == null ||
                  value.inFolder(folderId).isEmpty,
              onRetry: controller.retry,
              emptyBuilder: (_) => _EmptyFolder(isMissing: folder == null),
              dataBuilder: (context, value) =>
                  _DocumentList(library: value, folderId: folderId),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyFolder extends StatelessWidget {
  const _EmptyFolder({required this.isMissing});

  /// The folder was deleted while somebody was standing in it.
  final bool isMissing;

  @override
  Widget build(BuildContext context) {
    if (isMissing) {
      return NestEmptyView(
        title: AppCopy.documentsFolderFallbackTitle,
        message: AppCopy.documentProblem(DocumentProblem.folderNotFound),
        icon: Icons.folder_off_outlined,
      );
    }
    return const NestEmptyView(
      title: AppCopy.documentsFolderEmptyTitle,
      message: AppCopy.documentsFolderEmptyBody,
      icon: Icons.upload_file_outlined,
    );
  }
}

class _DocumentList extends StatelessWidget {
  const _DocumentList({required this.library, required this.folderId});

  final DocumentLibrary library;
  final String folderId;

  @override
  Widget build(BuildContext context) {
    final view = context.read<HouseholdView>();
    final controller = context.read<DocumentLibraryController>();
    final today = context.read<HouseholdClock>().today;
    final offline = context.watch<OfflineCopiesController>();
    final vocabulary = DocumentTags.vocabulary(
      library.folders
          .expand((folder) => library.inFolder(folder.id))
          .map((document) => document.tags),
    );
    return ListView(
      padding: const EdgeInsets.only(bottom: NestSpace.huge),
      children: [
        for (final document in library.inFolder(folderId))
          Padding(
            padding: const EdgeInsets.only(bottom: NestSpace.sm),
            child: DocumentRow(
              key: ValueKey(document.id),
              name: document.name,
              sizeBytes: document.sizeBytes,
              isImage: document.isPreviewable,
              byline: view.memberById(document.uploadedBy)?.displayName,
              tags: document.tags,
              expiresOn: document.expiresOn,
              today: today,
              isKeptOffline: offline.holds(
                ownerMemberId: null,
                documentId: document.id,
              ),
              onOpen: () => showDocumentSheet(
                context: context,
                document: document,
                folders: library.folders,
                canManage:
                    controller.isAdmin ||
                    (view.permissions.canEdit(HouseholdArea.documents) &&
                        document.uploadedBy == controller.memberId),
                tagSuggestions: vocabulary,
              ),
            ),
          ),
      ],
    );
  }
}
