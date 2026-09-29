import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../shared/async/async_state.dart';
import '../../../shared/failure/app_failure.dart';
import '../../../shared/state/action_failure.dart';
import '../../../shared/time/calendar_date.dart';
import '../../household/model/member.dart';
import '../data/document_directory.dart';
import '../data/document_picker.dart';
import '../data/pdf_page_renderer.dart';
import '../data/vault_repository.dart';
import '../data/vault_store.dart';
import '../model/document_limits.dart';
import '../model/picked_document.dart';
import '../model/vault_document.dart';
import '../model/vault_shelf.dart';
import '../model/vault_upload_details.dart';
import 'document_upload_runner.dart';
import 'document_upload_state.dart';
import 'scan_intake.dart';
import 'vault_listeners.dart';
import 'vault_lock_controller.dart';
import 'vault_upload_destination.dart';

/// The personal vaults, while they are unlocked (documents ADR-0002,
/// ADR-0003).
///
/// It follows the lock: unlocking opens the listeners, locking closes them and
/// drops everything they brought, so not even a document's name is held while
/// the vault is shut. Opening a document goes through the logged callable
/// before a byte is read.
final class VaultController extends ChangeNotifier with ActionFailureHolder {
  VaultController({
    required VaultRepository vaultRepository,
    required VaultStore vaultStore,
    required DocumentDirectory documentDirectory,
    required DocumentPicker documentPicker,
    required PdfPageRenderer pdfPageRenderer,
    required this.scanIntake,
    required this.lock,
    required this.householdId,
    required List<Member> members,
    required this.memberId,
    required this.viewerUid,
    required this.isFamily,
  }) : _repository = vaultRepository,
       _store = vaultStore,
       _directory = documentDirectory,
       _picker = documentPicker,
       _renderer = pdfPageRenderer {
    _listeners = VaultListeners(
      repository: vaultRepository,
      householdId: householdId,
      members: members,
      viewerMemberId: memberId,
      viewerUid: viewerUid,
      isFamily: isFamily,
      onShelf: _onShelf,
      onError: _onError,
    );
    _uploads = DocumentUploadRunner<VaultUploadDetails>(
      destination: VaultUploadDestination(
        repository: vaultRepository,
        store: vaultStore,
        householdId: householdId,
        memberId: memberId,
        viewerUid: viewerUid,
      ),
      notifyChange: notifyListeners,
      reportFailure: recordFailure,
    );
    lock.addListener(_followLock);
    _followLock();
  }

  final VaultRepository _repository;
  final VaultStore _store;
  final DocumentDirectory _directory;
  final DocumentPicker _picker;
  final PdfPageRenderer _renderer;
  final ScanIntake scanIntake;
  final VaultLockController lock;
  final String householdId;
  final String memberId;
  final String viewerUid;
  final bool isFamily;
  late final VaultListeners _listeners;
  late final DocumentUploadRunner<VaultUploadDetails> _uploads;

  var _isListening = false;

  /// A scan is being composed into its PDF, before the upload starts.
  bool get isPreparing => _uploads.isPreparing;
  AsyncState<VaultShelf> _shelf = const AsyncLoading();

  /// What is in the vaults. Loading while locked: there is nothing to show
  /// until the phone's lock has been passed.
  AsyncState<VaultShelf> get shelf => _shelf;

  /// The shelf once it has loaded, for a sheet that needs one fact from it.
  VaultShelf? get loadedShelf => switch (_shelf) {
    AsyncData(:final value) => value,
    _ => null,
  };

  DocumentUploadState? get upload => _uploads.state;
  bool get canRetryUpload => _uploads.canRetry;

  /// Whose vault the upload in flight, or the one that failed, is for.
  String? get uploadOwner => _uploads.details?.ownerMemberId;

  void _followLock() {
    if (lock.isUnlocked && !_isListening) {
      _isListening = true;
      _listeners.start();
    } else if (!lock.isUnlocked && _isListening) {
      _isListening = false;
      unawaited(_listeners.stop());
      _shelf = const AsyncLoading();
      clearFailureQuietly();
      notifyListeners();
    }
  }

  Future<void> retry() async {
    await _listeners.stop();
    _shelf = const AsyncLoading();
    notifyListeners();
    if (lock.isUnlocked) _listeners.start();
  }

  // ---- adding ----

  /// The sides of a scan, or null when somebody backed out of the scanner.
  Future<List<Uint8List>?> scan() async {
    clearFailureQuietly();
    lock.touch();
    try {
      return await scanIntake.capture();
    } on AppFailure catch (failure) {
      recordFailure(failure);
      return null;
    }
  }

  /// A file from the phone, refused early if the rules would refuse it.
  Future<PickedDocument?> pickFile() async {
    clearFailureQuietly();
    lock.touch();
    final file = await _picker.pickOne();
    if (file == null) return null;
    final problem = DocumentLimits.problemWith(
      contentType: file.contentType,
      sizeBytes: file.sizeBytes,
    );
    if (problem == null) return file;
    recordFailure(DocumentFailure(problem));
    return null;
  }

  Future<void> addScan(List<Uint8List> pages, VaultUploadDetails details) {
    clearFailureQuietly();
    lock.touch();
    return _uploads.prepareAndStart(
      details: details,
      prepare: () => scanIntake.compose(pages, name: details.name),
    );
  }

  Future<void> addFile(PickedDocument file, VaultUploadDetails details) {
    clearFailureQuietly();
    lock.touch();
    return _uploads.start(details: details, file: file);
  }

  Future<void> retryUpload() => _uploads.retry();
  Future<void> cancelUpload() => _uploads.cancel();

  void forgetUpload() {
    _uploads.forget();
    dismissActionFailure();
  }

  // ---- changing ----

  Future<void> editDocument(
    VaultDocument document, {
    required String name,
    required List<String> tags,
    required CalendarDate? expiresOn,
  }) {
    lock.touch();
    final trimmed = name.trim();
    if (trimmed.isEmpty) return Future.value();
    return runAction(
      () => _repository.editDocument(
        document: document,
        householdId: householdId,
        name: trimmed,
        tags: tags,
        expiresOn: expiresOn,
      ),
    );
  }

  /// Bytes first, then the row (`BE-07`, documents ADR-0001).
  Future<void> deleteDocument(VaultDocument document) => runAction(() async {
    lock.touch();
    try {
      await _store.remove(
        householdId: householdId,
        ownerMemberId: document.ownerMemberId,
        documentId: document.id,
      );
    } on NotFoundFailure {
      // An interrupted delete already got this far. Finish it.
    }
    await _repository.removeDocument(
      householdId: householdId,
      ownerMemberId: document.ownerMemberId,
      documentId: document.id,
    );
  });

  Future<void> share(String ownerMemberId, Member grantee) {
    final uid = grantee.claimedBy;
    if (uid == null) return Future.value();
    lock.touch();
    return runAction(
      () => _repository.grant(
        householdId: householdId,
        ownerMemberId: ownerMemberId,
        granteeUid: uid,
        granteeMemberId: grantee.id,
        grantedBy: memberId,
      ),
    );
  }

  Future<void> unshare(String ownerMemberId, String granteeUid) {
    lock.touch();
    return runAction(
      () => _repository.revoke(
        householdId: householdId,
        ownerMemberId: ownerMemberId,
        granteeUid: granteeUid,
      ),
    );
  }

  // ---- opening ----

  /// A document's pages as pictures: the server logs the view and issues the
  /// ticket first, then the bytes are read into memory and — for a PDF — drawn
  /// by the app itself (documents ADR-0003, ADR-0004).
  Future<List<Uint8List>> openPages(VaultDocument document) async {
    lock.touch();
    await _directory.openVaultDocument(
      householdId: householdId,
      ownerMemberId: document.ownerMemberId,
      documentId: document.id,
    );
    final bytes = await _store.read(
      householdId: householdId,
      ownerMemberId: document.ownerMemberId,
      documentId: document.id,
    );
    if (document.isImage) return [bytes];
    return _renderer.render(bytes);
  }

  // ---- the plumbing ----

  void _onShelf(VaultShelf shelf) {
    if (!_isListening) return;
    _shelf = AsyncData(shelf);
    notifyListeners();
  }

  void _onError(Object error) {
    _shelf = AsyncFailure(error is AppFailure ? error : UnknownFailure(error));
    notifyListeners();
  }

  @override
  void dispose() {
    lock.removeListener(_followLock);
    unawaited(_listeners.stop());
    super.dispose();
  }
}
