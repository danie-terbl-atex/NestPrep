import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../../../shared/copy/vault_copy.dart';
import '../../../shared/format/byte_size.dart';
import '../../../shared/time/household_clock.dart';
import '../model/document_tags.dart';
import '../model/share_target.dart';
import '../model/vault_document.dart';
import '../state/offline_copies_controller.dart';
import '../state/vault_controller.dart';
import 'document_badges.dart';
import 'document_details_sheet.dart';
import 'document_preview.dart';
import 'document_share_and_keep.dart';

/// Opening a vault document: its pages, drawn by the app from bytes read after
/// the server logged the open (documents ADR-0003), and — for its owner or an
/// admin — the ways to change or remove it.
Future<void> showVaultDocumentSheet({
  required BuildContext context,
  required VaultDocument document,
}) {
  final controller = context.read<VaultController>();
  final clock = context.read<HouseholdClock>();
  final offline = context.read<OfflineCopiesController>();
  return showNestSheet<void>(
    context: context,
    title: document.name,
    builder: (sheetContext) => MultiProvider(
      providers: [
        ChangeNotifierProvider<VaultController>.value(value: controller),
        ChangeNotifierProvider<OfflineCopiesController>.value(value: offline),
        Provider<HouseholdClock>.value(value: clock),
      ],
      child: _VaultDocumentBody(document: document),
    ),
  );
}

/// Closes itself the moment the vault locks — from the background, the timer
/// or the button — so a passport is never left on screen behind the lock
/// (documents ADR-0003).
class _VaultDocumentBody extends StatefulWidget {
  const _VaultDocumentBody({required this.document});

  final VaultDocument document;

  @override
  State<_VaultDocumentBody> createState() => _VaultDocumentBodyState();
}

class _VaultDocumentBodyState extends State<_VaultDocumentBody> {
  late final VaultController _controller = context.read<VaultController>();

  @override
  void initState() {
    super.initState();
    _controller.lock.addListener(_closeWhenLocked);
  }

  @override
  void dispose() {
    _controller.lock.removeListener(_closeWhenLocked);
    super.dispose();
  }

  void _closeWhenLocked() {
    if (!_controller.lock.isUnlocked && mounted) Navigator.of(context).pop();
  }

  VaultDocument get document => widget.document;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    final controller = context.read<VaultController>();
    final today = context.read<HouseholdClock>().today;
    final shelf = controller.loadedShelf;
    final canManage = shelf?.canManage(document.ownerMemberId) ?? false;
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          DocumentPreview(
            documentId: document.id,
            height: NestSize.pagesHeight,
            load: () => controller.openPages(document),
          ),
          const SizedBox(height: NestSpace.md),
          Text(
            [
              NestBytes.format(document.sizeBytes),
              VaultCopy.opensAreLogged,
            ].join(' · '),
            style: nest.text.caption.copyWith(color: nest.colors.inkTertiary),
          ),
          if (DocumentBadges.hasAny(
            expiresOn: document.expiresOn,
            tags: document.tags,
          )) ...[
            const SizedBox(height: NestSpace.md),
            DocumentBadges(
              expiresOn: document.expiresOn,
              tags: document.tags,
              today: today,
            ),
          ],
          const SizedBox(height: NestSpace.xl),
          DocumentShareAndKeep(
            target: ShareTarget(
              householdId: controller.householdId,
              ownerMemberId: document.ownerMemberId,
              documentId: document.id,
              name: document.name,
              tags: document.tags,
            ),
            // The owner or the family, never a grantee (documents ADR-0006)
            // — exactly who manages the vault.
            canShare: canManage,
            onKeep: () => context
                .read<OfflineCopiesController>()
                .saveVaultDocument(document),
          ),
          if (canManage) ...[
            const SizedBox(height: NestSpace.xxl),
            NestButton(
              label: VaultCopy.detailsTitle,
              variant: NestButtonVariant.tonal,
              icon: LucideIcons.pencil,
              onPressed: () => _edit(context, controller),
            ),
            const SizedBox(height: NestSpace.sm),
            NestButton(
              label: AppCopy.documentsDelete,
              variant: NestButtonVariant.danger,
              onPressed: () => _delete(context, controller),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _edit(BuildContext context, VaultController controller) async {
    final navigator = Navigator.of(context);
    final shelf = controller.loadedShelf;
    final details = await showDocumentDetailsSheet(
      context: context,
      title: VaultCopy.detailsTitle,
      saveLabel: AppCopy.householdSave,
      today: context.read<HouseholdClock>().today,
      initialName: document.name,
      initialTags: document.tags,
      initialExpiry: document.expiresOn,
      tagSuggestions: DocumentTags.vocabulary(
        shelf?.everyDocument.map((doc) => doc.tags) ?? const [],
      ),
    );
    if (details == null) return;
    await controller.editDocument(
      document,
      name: details.name,
      tags: details.tags,
      expiresOn: details.expiresOn,
    );
    navigator.pop();
  }

  Future<void> _delete(BuildContext context, VaultController controller) async {
    final navigator = Navigator.of(context);
    final confirmed = await showNestConfirm(
      context: context,
      title: AppCopy.documentsDeleteConfirm,
      message: AppCopy.documentsDeleteBody,
      confirmLabel: AppCopy.documentsDelete,
      cancelLabel: AppCopy.householdCancel,
      isDangerous: true,
    );
    if (confirmed != true) return;
    await controller.deleteDocument(document);
    navigator.pop();
  }
}
