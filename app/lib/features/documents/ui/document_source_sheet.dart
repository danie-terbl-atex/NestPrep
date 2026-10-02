import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/vault_copy.dart';

/// Where a new document comes from.
enum DocumentSource { scan, file }

/// Scan it with the camera, or choose a file the phone already has — the two
/// ways into a folder or a vault (documents ADR-0004). Null when somebody
/// closed the sheet, which is a choice.
Future<DocumentSource?> showDocumentSourceSheet(BuildContext context) =>
    showNestSheet<DocumentSource>(
      context: context,
      title: VaultCopy.addOptionsTitle,
      builder: (sheetContext) => const _DocumentSourceOptions(),
    );

class _DocumentSourceOptions extends StatelessWidget {
  const _DocumentSourceOptions();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        NestListRow(
          title: VaultCopy.scan,
          subtitle: VaultCopy.personEmptyBody,
          leading: const NestIconTile(
            icon: Icons.document_scanner_outlined,
            tint: NestTileTint.lilac,
          ),
          onTap: () => Navigator.of(context).pop(DocumentSource.scan),
        ),
        const SizedBox(height: NestSpace.sm),
        NestListRow(
          title: VaultCopy.addFile,
          leading: const NestIconTile(
            icon: Icons.upload_file_outlined,
            tint: NestTileTint.butter,
          ),
          onTap: () => Navigator.of(context).pop(DocumentSource.file),
        ),
      ],
    );
  }
}
