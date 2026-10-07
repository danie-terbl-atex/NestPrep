import 'dart:async';
import 'dart:typed_data';

import 'package:nestprep/features/documents/data/document_share_directory.dart';
import 'package:nestprep/features/documents/data/document_share_repository.dart';
import 'package:nestprep/features/documents/data/offline_access_check.dart';
import 'package:nestprep/features/documents/data/offline_copy_store.dart';
import 'package:nestprep/features/documents/data/offline_key_vault.dart';
import 'package:nestprep/features/documents/model/document_share.dart';
import 'package:nestprep/features/documents/model/offline_copy.dart';
import 'package:nestprep/features/documents/model/share_request.dart';
import 'package:nestprep/features/documents/model/shared_link.dart';
import 'package:nestprep/features/documents/state/offline_copies_controller.dart';
import 'package:nestprep/features/documents/state/offline_copy_source.dart';
import 'package:nestprep/features/documents/state/vault_lock_controller.dart';
import 'package:nestprep/features/household/data/invite_sharer.dart';
import 'package:nestprep/shared/failure/app_failure.dart';
import 'package:nestprep/shared/flags/feature_flags_controller.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

import 'fake_documents.dart';
import 'fake_feature_flag_source.dart';
import 'fake_invite_sharer.dart';
import 'fake_vault.dart';
import 'household_fixtures.dart';

export 'fake_feature_flag_source.dart' show FakeFeatureFlagSource;

/// Everything behind documents V2 (documents ADR-0006, ADR-0007) faked, with
/// the V2 switches from `fake_feature_flag_source.dart`: the shared-link
/// callables and list, the phone's offline copies, the server's say on them
/// and the keystore. One file because they are one substitution.

final class FakeDocumentShareDirectory implements DocumentShareDirectory {
  final created = <ShareRequest>[];
  final revoked = <String>[];
  AppFailure? failWith;
  Completer<void>? holdCreate;

  @override
  Future<SharedLink> create(ShareRequest request) async {
    created.add(request);
    await holdCreate?.future;
    final failure = failWith;
    if (failure != null) throw failure;
    return SharedLink(
      shareId: 'share-${created.length}',
      url: Uri.parse('https://share.nestprep.test/documentShare?t=abc123'),
      expiresAt: DateTime.utc(2026, 9, 30, 16),
    );
  }

  @override
  Future<void> revoke({
    required String householdId,
    required String shareId,
  }) async {
    final failure = failWith;
    if (failure != null) throw failure;
    revoked.add(shareId);
  }
}

final class FakeDocumentShareRepository implements DocumentShareRepository {
  final _shares = StreamController<List<DocumentShare>>.broadcast();
  final asked = <({bool isFamily, String viewerUid})>[];

  @override
  Stream<List<DocumentShare>> watchLiveShares({
    required String householdId,
    required String viewerUid,
    required bool isFamily,
    required DateTime now,
    int limit = DocumentShareRepository.liveShareLimit,
  }) {
    asked.add((isFamily: isFamily, viewerUid: viewerUid));
    return _shares.stream;
  }

  void emit(List<DocumentShare> shares) => _shares.add(shares);
  void fail(Object error) => _shares.addError(error);
  Future<void> close() => _shares.close();
}

/// The offline copies in memory, by account — the encryption itself is
/// `encrypted_offline_copy_store_test.dart`'s, against a real disk.
final class InMemoryOfflineCopyStore implements OfflineCopyStore {
  final byAccount = <String, Map<String, (OfflineCopy, Uint8List)>>{};
  AppFailure? failReadWith;
  AppFailure? failSaveWith;

  @override
  Future<List<OfflineCopy>> list(String uid) async => [
    for (final entry in (byAccount[uid] ?? const {}).values) entry.$1,
  ].reversed.toList();

  @override
  Future<void> save(String uid, OfflineCopy copy, Uint8List bytes) async {
    final failure = failSaveWith;
    if (failure != null) throw failure;
    (byAccount[uid] ??= {})[copy.key] = (copy, bytes);
  }

  @override
  Future<Uint8List> read(String uid, OfflineCopy copy) async {
    final failure = failReadWith;
    if (failure != null) throw failure;
    final kept = byAccount[uid]?[copy.key];
    if (kept == null) throw const NotFoundFailure();
    return kept.$2;
  }

  @override
  Future<void> remove(String uid, Iterable<OfflineCopy> copies) async {
    for (final copy in copies) {
      byAccount[uid]?.remove(copy.key);
    }
  }

  @override
  Future<void> keepOnly(String? uid) async =>
      byAccount.removeWhere((account, _) => account != uid);
}

final class FakeOfflineAccessCheck implements OfflineAccessCheck {
  /// What the server says about each document id; anything else is kept.
  final answers = <String, OfflineAccess>{};
  final checked = <String>[];

  @override
  Future<OfflineAccess> check(OfflineCopy copy) async {
    checked.add(copy.documentId);
    return answers[copy.documentId] ?? OfflineAccess.kept;
  }
}

final class InMemoryOfflineKeyVault implements OfflineKeyVault {
  final keys = <String, List<int>>{};
  AppFailure? failWith;

  @override
  Future<List<int>> keyFor(String uid) async {
    final failure = failWith;
    if (failure != null) throw failure;
    return keys[uid] ??= List<int>.generate(32, (index) => index + uid.length);
  }

  @override
  Future<Set<String>> accounts() async => keys.keys.toSet();

  @override
  Future<void> forget(String uid) async => keys.remove(uid);
}

/// A copy of [documentId], as a test would keep it.
OfflineCopy anOfflineCopy(
  String documentId, {
  String householdId = 'h1',
  String? ownerMemberId,
  String contentType = 'image/png',
}) => OfflineCopy(
  householdId: householdId,
  ownerMemberId: ownerMemberId,
  documentId: documentId,
  name: 'Copy of $documentId',
  contentType: contentType,
  sizeBytes: 1200,
  savedAt: DateTime.utc(2026, 9, 29, 8),
);

/// A live link to [documentName], ending [expiresAt].
DocumentShare aShare(
  String id, {
  String documentName = 'Medical aid card',
  DateTime? expiresAt,
  String? shiftId,
  bool hasPin = false,
  int openCount = 0,
  String? ownerMemberId = 'm-kid',
  String createdBy = 'm-sam',
}) => DocumentShare(
  id: id,
  scope: ownerMemberId == null ? 'household' : 'vault',
  ownerMemberId: ownerMemberId,
  documentId: 'doc-$id',
  documentName: documentName,
  contentType: 'application/pdf',
  createdBy: createdBy,
  createdByUid: 'uid-sam',
  expiresAt: expiresAt ?? DateTime.utc(2099),
  shiftId: shiftId,
  hasPin: hasPin,
  openCount: openCount,
);

/// The V2 switches, the shared-link callables and the offline copies, for a
/// screen pumped without the Documents shell. Goes after
/// `vaultLockProvider()`, whose lock the copies follow.
List<SingleChildWidget> documentToolProviders({
  FakeFeatureFlagSource? flags,
  InMemoryOfflineCopyStore? store,
  FakeDocumentShareDirectory? shareDirectory,
  bool flagsOn = true,
}) => [
  ChangeNotifierProvider<FeatureFlagsController>(
    create: (_) => FeatureFlagsController(
      source: flags ?? FakeFeatureFlagSource(),
      defaultOn: flagsOn,
    ),
  ),
  Provider<DocumentShareDirectory>.value(
    value: shareDirectory ?? FakeDocumentShareDirectory(),
  ),
  Provider<InviteSharer>.value(value: FakeInviteSharer()),
  ChangeNotifierProvider<OfflineCopiesController>(
    create: (context) => OfflineCopiesController(
      store: store ?? InMemoryOfflineCopyStore(),
      accessCheck: FakeOfflineAccessCheck(),
      source: OfflineCopySource(
        documentStore: FakeDocumentStore(),
        vaultStore: FakeVaultStore(),
        documentDirectory: FakeDocumentDirectory(),
        householdId: Fixtures.householdId,
      ),
      pdfPageRenderer: FakePdfPageRenderer(),
      lock: context.read<VaultLockController>(),
      householdId: Fixtures.householdId,
      uid: Fixtures.samUid,
    ),
  ),
];
