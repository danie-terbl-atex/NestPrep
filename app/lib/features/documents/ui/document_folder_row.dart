import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../model/document_folder.dart';

/// One shelf of the filing cabinet: what it is called, and how much is in it.
/// The count is words rather than a badge, because "Empty" is the thing
/// somebody most needs to know and a zero does not say it (`FE-13`).
class DocumentFolderRow extends StatelessWidget {
  const DocumentFolderRow({
    required this.folder,
    required this.count,
    required this.onOpen,
    this.onEdit,
    super.key,
  });

  final DocumentFolder folder;
  final int count;
  final VoidCallback onOpen;

  /// Admins only; the rules say the same (documents ADR-0001).
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    final edit = onEdit;
    return NestCard(
      variant: NestCardVariant.flat,
      padding: EdgeInsets.zero,
      child: NestListRow(
        title: folder.name,
        subtitle: AppCopy.documentsInFolder(count),
        leading: const NestIconTile(
          icon: Icons.folder_outlined,
          tint: NestTileTint.lilac,
        ),
        onTap: onOpen,
        trailing: edit == null
            ? null
            : NestIconButton(
                icon: Icons.tune,
                label: AppCopy.documentsEditFolder,
                variant: NestIconButtonVariant.plain,
                onPressed: edit,
              ),
      ),
    );
  }
}
