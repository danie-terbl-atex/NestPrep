import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../shared/async/async_state.dart';
import '../../../shared/failure/app_failure.dart';
import '../../../shared/state/action_failure.dart';
import '../data/document_directory.dart';
import '../data/document_opener.dart';
import '../data/document_picker.dart';
import '../data/document_repository.dart';
import '../data/document_store.dart';
import '../model/document_folder.dart';
import '../model/document_library.dart';
import '../model/document_limits.dart';
import '../model/household_document.dart';
import 'document_upload_runner.dart';
import 'document_upload_state.dart';

/// The documents screens' controller: two live reads become one library, with
/// one upload at a time running beside it.
///
/// Both screens share this controller, created on the shell route above them,
/// so walking into a folder and back out does not reopen the listeners
/// (foundation ADR-0006). Adding a file is `DocumentUploadRunner`'s job, which
/// is a separate file because it is a separate thing to get wrong.
final class DocumentLibraryController extends ChangeNotifier
    with ActionFailureHolder {
  DocumentLibraryController({
    required DocumentRepository documentRepository,
    required DocumentStore documentStore,
    required DocumentDirectory documentDirectory,
    required DocumentPicker documentPicker,
    required DocumentOpener documentOpener,
    required this.householdId,
    required this.memberId,
    required this.viewerUid,
    required this.isAdmin,
  }) : _repository = documentRepository,
       _store = documentStore,
       _directory = documentDirectory,
       _picker = documentPicker,
       _opener = documentOpener {
    _uploads = DocumentUploadRunner(
      documentRepository: documentRepository,
      documentStore: documentStore,
      householdId: householdId,
      memberId: memberId,
      viewerUid: viewerUid,
      notifyChange: notifyListeners,
      reportFailure: recordFailure,
    );
    _start();
  }

  final DocumentRepository _repository;
  final DocumentStore _store;
  final DocumentDirectory _directory;
  final DocumentPicker _picker;
  final DocumentOpener _opener;
  late final DocumentUploadRunner _uploads;

  final String householdId;

  /// The profile acting: whoever adds a document is recorded as this member.
  final String memberId;

  /// The account acting. Storage rules know uids and not profiles, so the
  /// object carries this one (documents ADR-0001).
  final String viewerUid;

  final bool isAdmin;

  StreamSubscription<List<DocumentFolder>>? _folderSubscription;
  StreamSubscription<List<HouseholdDocument>>? _documentSubscription;

  List<DocumentFolder>? _folders;
  List<HouseholdDocument>? _documents;
  AsyncState<DocumentLibrary> _library = const AsyncLoading();

  AsyncState<DocumentLibrary> get library => _library;

  /// The upload in flight, or null when nothing is being added.
  DocumentUploadState? get upload => _uploads.state;

  /// Whether the last upload left a file worth trying again with.
  bool get canRetryUpload => _uploads.canRetry;

  Future<void> retry() async {
    await _cancel();
    _folders = null;
    _documents = null;
    _library = const AsyncLoading();
    notifyListeners();
    _start();
  }

  // ---- folders (admin only; the rules say so too) ----

  Future<void> createFolder(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return Future.value();
    return runAction(
      () => _repository.createFolder(
        householdId: householdId,
        name: trimmed,
        createdBy: memberId,
      ),
    );
  }

  Future<void> renameFolder(DocumentFolder folder, String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return Future.value();
    return runAction(
      () => _repository.renameFolder(
        householdId: householdId,
        folderId: folder.id,
        name: trimmed,
      ),
    );
  }

  /// Through the callable, because only it can see whether the folder is still
  /// holding anything (documents ADR-0001).
  Future<void> deleteFolder(DocumentFolder folder) => runAction(
    () =>
        _directory.deleteFolder(householdId: householdId, folderId: folder.id),
  );

  // ---- documents ----

  /// Picks a file and adds it. Backing out of the picker is a choice, not a
  /// failure, so nothing is said about it (`FE-08`).
  Future<void> addDocument(String folderId) async {
    clearFailureQuietly();
    final file = await _picker.pickOne();
    if (file == null) return;

    // The rules refuse this too, on the bytes. Refusing here saves somebody
    // waiting for a 20 MiB upload to be told no (`FE-04`).
    final problem = DocumentLimits.problemWith(
      contentType: file.contentType,
      sizeBytes: file.sizeBytes,
    );
    if (problem != null) {
      recordFailure(DocumentFailure(problem));
      return;
    }
    await _uploads.start(folderId: folderId, file: file);
  }

  Future<void> retryUpload() => _uploads.retry();

  Future<void> cancelUpload() => _uploads.cancel();

  void forgetUpload() {
    _uploads.forget();
    dismissActionFailure();
  }

  Future<void> editDocument(
    HouseholdDocument document, {
    required String name,
    required String folderId,
  }) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return Future.value();
    return runAction(
      () => _repository.editDocument(
        householdId: householdId,
        documentId: document.id,
        name: trimmed,
        folderId: folderId,
      ),
    );
  }

  /// Bytes first, then the row.
  ///
  /// The other order leaves bytes nobody can see and nobody stops paying for.
  /// This one leaves, at worst, a row whose object has gone — visible, and its
  /// next delete finishes the job (`BE-07`, documents ADR-0001).
  Future<void> deleteDocument(HouseholdDocument document) => runAction(
    () async {
      try {
        await _store.remove(householdId: householdId, documentId: document.id);
      } on NotFoundFailure {
        // An interrupted delete already got this far. Finish it.
      }
      await _repository.removeDocument(
        householdId: householdId,
        documentId: document.id,
      );
    },
  );

  /// The bytes of a document, for the in-app preview of an image.
  Future<Uint8List> readDocument(HouseholdDocument document) =>
      _store.read(householdId: householdId, documentId: document.id);

  /// Hands a document the app cannot render to whatever on the device can.
  Future<void> openOutside(HouseholdDocument document) => runAction(() async {
    final link = await _store.openableLink(
      householdId: householdId,
      documentId: document.id,
    );
    if (!await _opener.open(link)) {
      throw const DocumentFailure(DocumentProblem.cannotOpen);
    }
  });

  // ---- the plumbing ----

  void _start() {
    _subscribe();
    unawaited(_openStorageAccess());
  }

  /// Puts this account's memberships on its own token before anything touches
  /// Storage. A refusal here is worth showing: without the claim every document
  /// in the household is unreadable, and "try again" is the right offer.
  Future<void> _openStorageAccess() async {
    try {
      await _directory.syncAccess();
    } on AppFailure catch (failure) {
      recordFailure(failure);
    }
  }

  void _subscribe() {
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

  void _publish() {
    final folders = _folders;
    final documents = _documents;
    if (folders == null || documents == null) return;
    _library = AsyncData(
      DocumentLibrary(folders: folders, documents: documents),
    );
    notifyListeners();
  }

  void _onError(Object error) {
    _library = AsyncFailure(
      error is AppFailure ? error : UnknownFailure(error),
    );
    notifyListeners();
  }

  Future<void> _cancel() async {
    await _folderSubscription?.cancel();
    await _documentSubscription?.cancel();
    _folderSubscription = null;
    _documentSubscription = null;
  }

  @override
  void dispose() {
    unawaited(_cancel());
    super.dispose();
  }
}
