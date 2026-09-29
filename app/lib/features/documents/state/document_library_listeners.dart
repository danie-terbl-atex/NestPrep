import 'dart:async';

import '../../../shared/async/async_state.dart';
import '../../../shared/failure/app_failure.dart';
import '../data/document_repository.dart';
import '../model/document_folder.dart';
import '../model/document_library.dart';
import '../model/household_document.dart';

/// The household's two live reads — folders and documents — become one
/// library, published once both have answered (documents ADR-0001).
///
/// Apart from the controller so that the controller holds what a person does
/// and this holds what the database says.
final class DocumentLibraryListeners {
  DocumentLibraryListeners({
    required this._repository,
    required this.householdId,
    required this._onLibrary,
  });

  final DocumentRepository _repository;
  final String householdId;
  final void Function(AsyncState<DocumentLibrary> library) _onLibrary;

  StreamSubscription<List<DocumentFolder>>? _folderSubscription;
  StreamSubscription<List<HouseholdDocument>>? _documentSubscription;
  List<DocumentFolder>? _folders;
  List<HouseholdDocument>? _documents;

  void start() {
    _folderSubscription = _repository.watchFolders(householdId).listen((
      folders,
    ) {
      _folders = folders;
      _publish();
    }, onError: _onError);
    _documentSubscription = _repository.watchDocuments(householdId).listen((
      documents,
    ) {
      _documents = documents;
      _publish();
    }, onError: _onError);
  }

  Future<void> stop() async {
    await _folderSubscription?.cancel();
    await _documentSubscription?.cancel();
    _folderSubscription = null;
    _documentSubscription = null;
    _folders = null;
    _documents = null;
  }

  void _publish() {
    final folders = _folders;
    final documents = _documents;
    if (folders == null || documents == null) return;
    _onLibrary(
      AsyncData(DocumentLibrary(folders: folders, documents: documents)),
    );
  }

  void _onError(Object error) {
    _onLibrary(
      AsyncFailure(error is AppFailure ? error : UnknownFailure(error)),
    );
  }
}
