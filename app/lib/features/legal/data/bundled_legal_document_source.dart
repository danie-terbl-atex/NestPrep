import 'package:flutter/services.dart';

import '../../../shared/failure/app_failure.dart';
import '../../../shared/log/app_log.dart';
import '../model/legal_document.dart';
import '../model/legal_document_parser.dart';
import '../model/legal_kind.dart';
import 'legal_document_source.dart';

/// The documents from the app's own asset bundle.
///
/// A document that will not load or parse is our bug, never the person's: it
/// is logged with its cause and surfaces as the screen's error state rather
/// than a stack trace (`FE-09`, `ENG-10`).
final class BundledLegalDocumentSource implements LegalDocumentSource {
  BundledLegalDocumentSource({AssetBundle? bundle})
    : _bundle = bundle ?? rootBundle;

  final AssetBundle _bundle;

  @override
  Future<LegalDocument> load(LegalKind kind) async {
    try {
      final source = await _bundle.loadString(kind.assetPath);
      return parseLegalDocument(source);
    } on Object catch (error) {
      AppLog.failure('legal document', code: 'unreadable', error: error);
      throw UnknownFailure(error);
    }
  }
}
