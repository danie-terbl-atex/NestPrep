import 'package:file_selector/file_selector.dart';

import '../../../shared/copy/app_copy.dart';
import '../model/document_limits.dart';
import '../model/picked_document.dart';
import 'document_picker.dart';

/// The device's own file picker, narrowed to what a household files.
///
/// The type groups are a courtesy: they stop somebody hunting for a video the
/// rules would refuse anyway. What is actually enforced is `storage.rules`,
/// because a picker is a suggestion and a rule is not (`FE-04`, `BE-20`).
final class FileSelectorDocumentPicker implements DocumentPicker {
  const FileSelectorDocumentPicker();

  static const _group = XTypeGroup(
    // Shown by the desktop file dialogs; unused on the two platforms this app
    // builds for, and still copy (`FE-19`).
    label: AppCopy.documentsPickFile,
    extensions: ['pdf', 'jpg', 'jpeg', 'png', 'heic', 'webp'],
    mimeTypes: [
      'application/pdf',
      'image/jpeg',
      'image/png',
      'image/heic',
      'image/webp',
    ],
  );

  @override
  Future<PickedDocument?> pickOne() async {
    final file = await openFile(acceptedTypeGroups: const [_group]);
    if (file == null) return null;

    final bytes = await file.readAsBytes();
    return PickedDocument(
      name: file.name,
      // A device that will not say what a file is gets the same answer as one
      // that says something we do not keep: the limits refuse it by name.
      contentType: _typeOf(file),
      bytes: bytes,
    );
  }

  String _typeOf(XFile file) {
    final declared = file.mimeType;
    if (declared != null &&
        DocumentLimits.keptContentTypes.contains(declared)) {
      return declared;
    }
    return _fromExtension(file.name) ?? '';
  }

  /// Android's picker often hands back no mime type at all, and the name is
  /// then the only thing there is to go on. A guess that is wrong is refused by
  /// the rules, which is the correct outcome either way.
  String? _fromExtension(String name) {
    final dot = name.lastIndexOf('.');
    if (dot < 0) return null;
    return switch (name.substring(dot + 1).toLowerCase()) {
      'pdf' => 'application/pdf',
      'jpg' || 'jpeg' => 'image/jpeg',
      'png' => 'image/png',
      'heic' => 'image/heic',
      'webp' => 'image/webp',
      _ => null,
    };
  }
}
