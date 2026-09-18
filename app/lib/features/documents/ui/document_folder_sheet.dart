import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../model/document_folder.dart';
import '../model/document_limits.dart';

/// What somebody typed for a folder, or null when they backed out.
typedef DocumentFolderEdit = ({String name, bool isDeleted});

/// Names a new folder, or renames and deletes an existing one.
///
/// Deleting is offered here rather than on the row because it is the one action
/// that can be refused for a reason nobody expected — a folder that still holds
/// documents — and the refusal belongs beside the thing that asked for it.
Future<DocumentFolderEdit?> showDocumentFolderSheet({
  required BuildContext context,
  DocumentFolder? existing,
}) {
  return showNestSheet<DocumentFolderEdit>(
    context: context,
    title: existing == null
        ? AppCopy.documentsAddFolder
        : AppCopy.documentsEditFolder,
    builder: (sheetContext) => _DocumentFolderSheetBody(existing: existing),
  );
}

class _DocumentFolderSheetBody extends StatefulWidget {
  const _DocumentFolderSheetBody({required this.existing});

  final DocumentFolder? existing;

  @override
  State<_DocumentFolderSheetBody> createState() =>
      _DocumentFolderSheetBodyState();
}

class _DocumentFolderSheetBodyState extends State<_DocumentFolderSheetBody> {
  late final _name = TextEditingController(text: widget.existing?.name ?? '');

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final canSave = _name.text.trim().isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        NestTextField(
          label: AppCopy.documentsFolderNameLabel,
          hint: AppCopy.documentsFolderNameHint,
          controller: _name,
          autofocus: true,
          textInputAction: TextInputAction.done,
          // The cap is a rule (`storage.rules` and `firestore.rules` both hold
          // it); stopping the keyboard at it is how somebody sees it rather
          // than being silently trimmed afterwards (`FE-10`).
          inputFormatters: [
            LengthLimitingTextInputFormatter(DocumentLimits.nameMaxLength),
          ],
          onChanged: (_) => setState(() {}),
          onSubmitted: (_) => _save(),
        ),
        const SizedBox(height: NestSpace.xxl),
        NestButton(
          label: AppCopy.householdSave,
          onPressed: canSave ? _save : null,
        ),
        if (widget.existing != null) ...[
          const SizedBox(height: NestSpace.sm),
          NestButton(
            label: AppCopy.documentsDeleteFolder,
            variant: NestButtonVariant.danger,
            onPressed: _delete,
          ),
        ],
      ],
    );
  }

  void _save() {
    final name = _name.text.trim();
    if (name.isEmpty) return;
    Navigator.of(context).pop((name: name, isDeleted: false));
  }

  Future<void> _delete() async {
    final navigator = Navigator.of(context);
    final confirmed = await showNestConfirm(
      context: context,
      title: AppCopy.documentsDeleteFolderConfirm,
      message: AppCopy.documentsDeleteFolderBody,
      confirmLabel: AppCopy.documentsDeleteFolder,
      cancelLabel: AppCopy.householdCancel,
      isDangerous: true,
    );
    if (confirmed != true) return;
    navigator.pop((name: widget.existing?.name ?? '', isDeleted: true));
  }
}
