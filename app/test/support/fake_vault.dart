import 'dart:async';
import 'dart:typed_data';

import 'package:nestprep/features/documents/data/device_lock.dart';
import 'package:nestprep/features/documents/data/document_scanner.dart';
import 'package:nestprep/features/documents/data/document_store.dart';
import 'package:nestprep/features/documents/data/pdf_page_renderer.dart';
import 'package:nestprep/features/documents/data/scan_composer.dart';
import 'package:nestprep/features/documents/data/vault_repository.dart';
import 'package:nestprep/features/documents/data/vault_store.dart';
import 'package:nestprep/features/documents/model/picked_document.dart';
import 'package:nestprep/features/documents/model/vault_document.dart';
import 'package:nestprep/features/documents/model/vault_grant.dart';
import 'package:nestprep/features/documents/model/vault_lock_state.dart';
import 'package:nestprep/features/documents/model/vault_view.dart';
import 'package:nestprep/features/documents/state/scan_intake.dart';
import 'package:nestprep/features/documents/state/vault_lock_controller.dart';
import 'package:nestprep/shared/copy/vault_copy.dart';
import 'package:nestprep/shared/failure/app_failure.dart';
import 'package:nestprep/shared/time/calendar_date.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

import 'fake_documents.dart';

/// Everything behind the vault's controllers, faked: the vaults' metadata and
/// bytes, the phone's lock, its scanner, the scan pipeline and the PDF
/// renderer. One file because they are one substitution, like
/// `fake_documents.dart` beside it. Nothing here touches a plugin.

final class FakeVaultRepository implements VaultRepository {
  final _vaults = <String, StreamController<List<VaultDocument>>>{};
  final _grants = <String, StreamController<List<VaultGrant>>>{};
  final _grantsTo = <String, StreamController<bool>>{};
  final _views = <String, StreamController<List<VaultView>>>{};

  AppFailure? failWritesWith;
  var _nextId = 0;
  final added = <VaultDocumentDraft>[];
  final edited =
      <
        ({String id, String name, List<String> tags, CalendarDate? expiresOn})
      >[];
  final removed = <String>[];
  final granted = <({String owner, String granteeUid, String memberId})>[];
  final revoked = <({String owner, String granteeUid})>[];

  /// Which vaults have a listener open — the thing locking must close.
  Set<String> get watchedVaults => {
    for (final entry in _vaults.entries)
      if (entry.value.hasListener) entry.key,
  };

  StreamController<T> _controller<T>(
    Map<String, StreamController<T>> map,
    String key,
  ) => map.putIfAbsent(key, StreamController<T>.broadcast);

  void emitVault(String owner, List<VaultDocument> documents) =>
      _controller(_vaults, owner).add([
        for (final document in documents)
          document.copyWith(ownerMemberId: owner),
      ]);
  void emitGrants(String owner, List<VaultGrant> grants) =>
      _controller(_grants, owner).add(grants);
  void emitGrantTo(String owner, {required bool isGranted}) =>
      _controller(_grantsTo, owner).add(isGranted);
  void emitViews(String owner, List<VaultView> views) => _controller(
    _views,
    owner,
  ).add([for (final view in views) view.copyWith(ownerMemberId: owner)]);
  void failVault(String owner, Object error) =>
      _controller(_vaults, owner).addError(error);
  void failViews(String owner, Object error) =>
      _controller(_views, owner).addError(error);

  Future<void> close() async {
    for (final map in <Map<String, StreamController<Object?>>>[
      _vaults,
      _grants,
      _grantsTo,
      _views,
    ]) {
      for (final controller in map.values) {
        await controller.close();
      }
    }
  }

  @override
  Stream<List<VaultDocument>> watchVault({
    required String householdId,
    required String ownerMemberId,
  }) => _controller(_vaults, ownerMemberId).stream;

  @override
  Stream<List<VaultGrant>> watchGrants({
    required String householdId,
    required String ownerMemberId,
  }) => _controller(_grants, ownerMemberId).stream;

  @override
  Stream<bool> watchGrantTo({
    required String householdId,
    required String ownerMemberId,
    required String granteeUid,
  }) => _controller(_grantsTo, ownerMemberId).stream;

  @override
  Stream<List<VaultView>> watchViews({
    required String householdId,
    required String ownerMemberId,
  }) => _controller(_views, ownerMemberId).stream;

  @override
  String newDocumentId({
    required String householdId,
    required String ownerMemberId,
  }) => 'vault-doc-${++_nextId}';

  @override
  Future<void> addDocument(VaultDocumentDraft draft) async {
    _refuseIfAsked();
    added.add(draft);
  }

  @override
  Future<void> editDocument({
    required VaultDocument document,
    required String householdId,
    required String name,
    required List<String> tags,
    required CalendarDate? expiresOn,
  }) async {
    _refuseIfAsked();
    edited.add((id: document.id, name: name, tags: tags, expiresOn: expiresOn));
  }

  @override
  Future<void> removeDocument({
    required String householdId,
    required String ownerMemberId,
    required String documentId,
  }) async {
    _refuseIfAsked();
    removed.add(documentId);
  }

  @override
  Future<void> grant({
    required String householdId,
    required String ownerMemberId,
    required String granteeUid,
    required String granteeMemberId,
    required String grantedBy,
  }) async {
    _refuseIfAsked();
    granted.add((
      owner: ownerMemberId,
      granteeUid: granteeUid,
      memberId: granteeMemberId,
    ));
  }

  @override
  Future<void> revoke({
    required String householdId,
    required String ownerMemberId,
    required String granteeUid,
  }) async {
    _refuseIfAsked();
    revoked.add((owner: ownerMemberId, granteeUid: granteeUid));
  }

  void _refuseIfAsked() {
    final failure = failWritesWith;
    if (failure != null) throw failure;
  }
}

final class FakeVaultStore implements VaultStore {
  FakeDocumentUpload? nextUpload;
  AppFailure? failReadWith;
  Uint8List bytes = Uint8List.fromList([1, 2, 3]);
  final uploads =
      <({String owner, String documentId, String uploaderUid, String name})>[];
  final reads = <String>[];
  final removedBytes = <String>[];

  @override
  DocumentUpload upload({
    required String householdId,
    required String ownerMemberId,
    required String documentId,
    required String uploaderUid,
    required PickedDocument file,
  }) {
    uploads.add((
      owner: ownerMemberId,
      documentId: documentId,
      uploaderUid: uploaderUid,
      name: file.name,
    ));
    return nextUpload ??= FakeDocumentUpload();
  }

  @override
  Future<Uint8List> read({
    required String householdId,
    required String ownerMemberId,
    required String documentId,
  }) async {
    final failure = failReadWith;
    if (failure != null) throw failure;
    reads.add(documentId);
    return bytes;
  }

  @override
  Future<void> remove({
    required String householdId,
    required String ownerMemberId,
    required String documentId,
  }) async {
    removedBytes.add(documentId);
  }
}

final class FakeDeviceLock implements DeviceLock {
  FakeDeviceLock([this.outcome = UnlockOutcome.unlocked]);

  UnlockOutcome outcome;
  var asked = 0;

  /// When set, the prompt stays up until this completes.
  Completer<void>? holdPrompt;

  @override
  Future<UnlockOutcome> unlock(String reason) async {
    asked++;
    await holdPrompt?.future;
    return outcome;
  }
}

final class FakeDocumentScanner implements DocumentScanner {
  /// What the next scan returns; null is somebody backing out.
  List<Uint8List>? next = [
    Uint8List.fromList([1]),
    Uint8List.fromList([2]),
  ];
  AppFailure? failWith;
  int? askedForPages;

  @override
  Future<List<Uint8List>?> scan({required int maxPages}) async {
    askedForPages = maxPages;
    final failure = failWith;
    if (failure != null) throw failure;
    return next;
  }
}

final class FakeScanComposer implements ScanComposer {
  Uint8List result = Uint8List.fromList([0x25, 0x50, 0x44, 0x46]);
  AppFailure? failWith;
  final composed = <int>[];

  @override
  Future<Uint8List> compose(List<Uint8List> pages) async {
    final failure = failWith;
    if (failure != null) throw failure;
    composed.add(pages.length);
    return result;
  }
}

final class FakePdfPageRenderer implements PdfPageRenderer {
  List<Uint8List> pages = [
    Uint8List.fromList([9]),
  ];
  AppFailure? failWith;
  var renders = 0;

  @override
  Future<List<Uint8List>> render(Uint8List pdf) async {
    renders++;
    final failure = failWith;
    if (failure != null) throw failure;
    return pages;
  }
}

/// A scan intake over fakes, for the controllers that take one.
ScanIntake fakeScanIntake({
  FakeDocumentScanner? scanner,
  FakeScanComposer? composer,
}) => ScanIntake(
  scanner: scanner ?? FakeDocumentScanner(),
  composer: composer ?? FakeScanComposer(),
);

VaultDocument vaultDocument(
  String id, {
  String name = 'Passport',
  String contentType = 'application/pdf',
  List<String> tags = const [],
  CalendarDate? expiresOn,
  String uploadedBy = 'm-sam',
}) => VaultDocument(
  id: id,
  name: name,
  contentType: contentType,
  sizeBytes: 300000,
  uploadedBy: uploadedBy,
  tags: tags,
  expiresOn: expiresOn,
);

/// A vault lock over a fake device lock, as a provider — every screen under
/// Documents reads whether the vaults are open.
SingleChildWidget vaultLockProvider({FakeDeviceLock? deviceLock}) =>
    ChangeNotifierProvider<VaultLockController>(
      create: (_) => VaultLockController(
        deviceLock: deviceLock ?? FakeDeviceLock(),
        reason: VaultCopy.unlockReason,
      ),
    );
