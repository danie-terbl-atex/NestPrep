import 'package:flutter/foundation.dart';

import '../../../shared/async/async_state.dart';
import '../../../shared/failure/app_failure.dart';
import '../../../shared/links/external_link_opener.dart';
import '../data/legal_document_source.dart';
import '../model/legal_document.dart';
import '../model/legal_kind.dart';

/// One legal document, read once from the app's own copy (accounts ADR-0005).
/// It is not live — the document cannot change under a running app — so there
/// is no listener, only a load and a retry.
final class LegalDocumentController extends ChangeNotifier {
  LegalDocumentController({
    required LegalDocumentSource source,
    required ExternalLinkOpener linkOpener,
    required this.kind,
  }) : _documents = source,
       _links = linkOpener {
    _load();
  }

  final LegalDocumentSource _documents;
  final ExternalLinkOpener _links;
  final LegalKind kind;

  AsyncState<LegalDocument> _document = const AsyncLoading();
  bool _linkWouldNotOpen = false;
  bool _isDisposed = false;

  AsyncState<LegalDocument> get document => _document;

  /// The last link followed found nothing on the phone to open it — the
  /// screen says so rather than the tap doing nothing (`FE-08`).
  bool get linkWouldNotOpen => _linkWouldNotOpen;

  Future<void> openLink(Uri link) async {
    final wouldNotOpen = !await _links.open(link);
    if (_isDisposed || wouldNotOpen == _linkWouldNotOpen) return;
    _linkWouldNotOpen = wouldNotOpen;
    notifyListeners();
  }

  Future<void> retry() {
    _document = const AsyncLoading();
    notifyListeners();
    return _load();
  }

  Future<void> _load() async {
    try {
      final document = await _documents.load(kind);
      _document = AsyncData(document);
    } on AppFailure catch (failure) {
      _document = AsyncFailure(failure);
    }
    if (!_isDisposed) notifyListeners();
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }
}
