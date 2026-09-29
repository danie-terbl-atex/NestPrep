import 'package:nestprep/features/documents/model/document_share.dart';

import 'model_fixtures.dart';

/// The stored model of documents V2 (documents ADR-0006), every field filled,
/// spread into `modelFixtures()` beside the other features'. `OfflineCopy` is
/// not here: it never touches Firestore, and its encrypted JSON has its own
/// round trip in `encrypted_offline_copy_store_test.dart`.
List<ModelFixture> documentToolsModelFixtures() {
  final at = fixtureInstant;
  final share = DocumentShare(
    id: 'share-1',
    scope: 'vault',
    ownerMemberId: 'm2',
    documentId: 'v1',
    documentName: 'Medical aid card',
    contentType: 'application/pdf',
    createdBy: 'm1',
    createdByUid: 'uid-sam',
    createdAt: at,
    expiresAt: at,
    shiftId: 'shift-1',
    hasPin: true,
    openCount: 2,
    lastOpenedAt: at,
  );
  return [
    ModelFixture(
      label: 'DocumentShare',
      id: 'share-1',
      value: share,
      toJson: share.toJson,
      fromJson: DocumentShare.fromJson,
      keys: const {
        'scope',
        'ownerMemberId',
        'documentId',
        'documentName',
        'contentType',
        'createdBy',
        'createdByUid',
        'createdAt',
        'expiresAt',
        'shiftId',
        'hasPin',
        'status',
        'openCount',
        'lastOpenedAt',
      },
      note:
          'written only by the shared-link Functions; the app reads it and '
          'never writes it (documents ADR-0006). `purgeAt` is the TTL field, '
          'which the app has no use for.',
    ),
  ];
}
