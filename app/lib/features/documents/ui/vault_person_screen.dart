import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../../../shared/copy/vault_copy.dart';
import '../../../shared/failure/app_failure.dart';
import '../../../shared/time/household_clock.dart';
import '../../accounts/ui/account_menu_button.dart';
import '../../household/model/household_view.dart';
import '../model/vault_shelf.dart';
import '../state/vault_controller.dart';
import 'add_to_vault.dart';
import 'document_row.dart';
import 'document_upload_card.dart';
import 'vault_access_sheet.dart';
import 'vault_document_sheet.dart';

/// One person's vault. The add and share controls live in the header, outside
/// the view that becomes the empty state — the first person to open an empty
/// vault can always fill it (`FE-08`, and the vault lesson on exactly that).
class VaultPersonScreen extends StatelessWidget {
  const VaultPersonScreen({required this.memberId, super.key});

  final String memberId;

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<VaultController>();
    final member = context.read<HouseholdView>().memberById(memberId);
    final canManage = controller.loadedShelf?.canManage(memberId) ?? false;
    final failure = controller.actionFailure;
    final showsUpload =
        controller.uploadOwner == memberId &&
        (controller.upload != null || controller.canRetryUpload);
    return NestScaffold(
      title: member == null
          ? VaultCopy.homeTitle
          : VaultCopy.vaultOf(member.displayName),
      leading: context.canPop()
          ? NestIconButton(
              icon: Icons.arrow_back,
              label: AppCopy.back,
              variant: NestIconButtonVariant.plain,
              onPressed: context.pop,
            )
          : null,
      trailing: [
        if (canManage) ...[
          NestIconButton(
            icon: Icons.group_outlined,
            label: VaultCopy.accessTitle,
            onPressed: () =>
                showVaultAccessSheet(context: context, ownerMemberId: memberId),
          ),
          NestIconButton(
            icon: Icons.document_scanner_outlined,
            label: AppCopy.documentsAdd,
            variant: NestIconButtonVariant.accent,
            onPressed: controller.upload != null
                ? null
                : () => addToVault(context, memberId),
          ),
        ],
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
          if (showsUpload)
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
            child: NestAsyncView<VaultShelf>(
              state: controller.shelf,
              isEmpty: (shelf) =>
                  !shelf.canOpen(memberId) ||
                  shelf.documentsOf(memberId).isEmpty,
              onRetry: controller.retry,
              emptyBuilder: (_) => _EmptyVault(
                canManage: canManage,
                isShut: !(controller.loadedShelf?.canOpen(memberId) ?? true),
              ),
              dataBuilder: (context, shelf) =>
                  _VaultDocuments(shelf: shelf, memberId: memberId),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyVault extends StatelessWidget {
  const _EmptyVault({required this.canManage, required this.isShut});

  final bool canManage;

  /// A link to a vault this person may not open — shared once, since revoked.
  final bool isShut;

  @override
  Widget build(BuildContext context) {
    if (isShut) {
      return NestEmptyView(
        title: VaultCopy.homeTitle,
        message: AppCopy.documentProblem(DocumentProblem.vaultNotShared),
        icon: Icons.lock_person_outlined,
      );
    }
    return NestEmptyView(
      title: VaultCopy.personEmptyTitle,
      message: canManage
          ? VaultCopy.personEmptyBody
          : VaultCopy.personEmptyBodyReadOnly,
      icon: Icons.document_scanner_outlined,
    );
  }
}

class _VaultDocuments extends StatelessWidget {
  const _VaultDocuments({required this.shelf, required this.memberId});

  final VaultShelf shelf;
  final String memberId;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    final today = context.read<HouseholdClock>().today;
    final view = context.read<HouseholdView>();
    return ListView(
      padding: const EdgeInsets.only(bottom: NestSpace.huge),
      children: [
        Text(
          shelf.canManage(memberId)
              ? VaultCopy.opensAreLogged
              : VaultCopy.readOnlyNote,
          style: nest.text.caption.copyWith(color: nest.colors.inkTertiary),
        ),
        const SizedBox(height: NestSpace.lg),
        for (final document in shelf.documentsOf(memberId))
          Padding(
            padding: const EdgeInsets.only(bottom: NestSpace.sm),
            child: DocumentRow(
              key: ValueKey(document.id),
              name: document.name,
              sizeBytes: document.sizeBytes,
              isImage: document.isImage,
              byline: view.memberById(document.uploadedBy)?.displayName,
              tags: document.tags,
              expiresOn: document.expiresOn,
              today: today,
              onOpen: () =>
                  showVaultDocumentSheet(context: context, document: document),
            ),
          ),
      ],
    );
  }
}
