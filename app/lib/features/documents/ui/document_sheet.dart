import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../../../shared/format/byte_size.dart';
import '../model/document_folder.dart';
import '../model/document_limits.dart';
import '../model/household_document.dart';
import '../state/document_library_controller.dart';
import 'document_preview.dart';

/// Opening a document: what it is, what is in it if the app can show that, and
/// the ways to change or remove it.
///
/// The rules allow the uploader or an admin to rename, move and delete; a
/// refusal comes back as copy on the list behind this sheet (`FE-04`).
Future<void> showDocumentSheet({
  required BuildContext context,
  required HouseholdDocument document,
  required List<DocumentFolder> folders,
  required bool canManage,
}) {
  final controller = context.read<DocumentLibraryController>();
  return showNestSheet<void>(
    context: context,
    title: document.name,
    builder: (sheetContext) => _DocumentSheetBody(
      document: document,
      folders: folders,
      canManage: canManage,
      controller: controller,
    ),
  );
}

class _DocumentSheetBody extends StatefulWidget {
  const _DocumentSheetBody({
    required this.document,
    required this.folders,
    required this.canManage,
    required this.controller,
  });

  final HouseholdDocument document;
  final List<DocumentFolder> folders;
  final bool canManage;
  final DocumentLibraryController controller;

  @override
  State<_DocumentSheetBody> createState() => _DocumentSheetBodyState();
}

class _DocumentSheetBodyState extends State<_DocumentSheetBody> {
  late final _name = TextEditingController(text: widget.document.name);
  late String _folderId = widget.document.folderId;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    final document = widget.document;
    final canSave = _name.text.trim().isNotEmpty;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (document.isPreviewable)
            DocumentPreview(
              documentId: document.id,
              load: () => widget.controller.readDocument(document),
            )
          else
            NestBanner(
              message: AppCopy.documentsOfflineNote,
              actionLabel: AppCopy.documentsOpenOutside,
              onAction: () => widget.controller.openOutside(document),
            ),
          const SizedBox(height: NestSpace.lg),
          Text(
            NestBytes.format(document.sizeBytes),
            style: nest.text.caption.copyWith(color: nest.colors.inkTertiary),
          ),
          const SizedBox(height: NestSpace.lg),
          if (widget.canManage) ...[
            NestTextField(
              label: AppCopy.documentsNameLabel,
              controller: _name,
              textInputAction: TextInputAction.done,
              inputFormatters: [
                LengthLimitingTextInputFormatter(DocumentLimits.nameMaxLength),
              ],
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: NestSpace.lg),
            const NestSectionHeader(title: AppCopy.documentsFolderLabel),
            const SizedBox(height: NestSpace.sm),
            Wrap(
              spacing: NestSpace.sm,
              runSpacing: NestSpace.sm,
              children: [
                for (final folder in widget.folders)
                  NestChip(
                    label: folder.name,
                    isSelected: folder.id == _folderId,
                    onTap: () => setState(() => _folderId = folder.id),
                  ),
              ],
            ),
            const SizedBox(height: NestSpace.xxl),
            NestButton(
              label: AppCopy.householdSave,
              onPressed: canSave ? _save : null,
            ),
            const SizedBox(height: NestSpace.sm),
            NestButton(
              label: AppCopy.documentsDelete,
              variant: NestButtonVariant.danger,
              onPressed: _delete,
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _save() async {
    final navigator = Navigator.of(context);
    await widget.controller.editDocument(
      widget.document,
      name: _name.text,
      folderId: _folderId,
    );
    navigator.pop();
  }

  Future<void> _delete() async {
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
    await widget.controller.deleteDocument(widget.document);
    navigator.pop();
  }
}
