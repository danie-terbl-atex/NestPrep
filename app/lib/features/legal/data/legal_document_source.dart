import '../model/legal_document.dart';
import '../model/legal_kind.dart';

/// Where the app reads its privacy policy and terms from: the copies shipped
/// inside it, so they open with no connection and always match the version a
/// person is asked to accept (accounts ADR-0005).
abstract interface class LegalDocumentSource {
  Future<LegalDocument> load(LegalKind kind);
}
