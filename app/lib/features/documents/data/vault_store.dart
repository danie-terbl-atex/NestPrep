import 'dart:typed_data';

import '../model/picked_document.dart';
import 'document_store.dart';

/// The bytes of the personal vaults: Cloud Storage, at
/// `households/{h}/vaults/{memberId}/{documentId}` (documents ADR-0002).
///
/// Deliberately smaller than `DocumentStore`: there is **no link**. A download
/// URL authorises by possession and outlives every rule, so a vault document is
/// only ever read as bytes, into memory, after `openVaultDocument` has logged
/// the view and issued the ticket the read rule checks (documents ADR-0003).
abstract interface class VaultStore {
  DocumentUpload upload({
    required String householdId,
    required String ownerMemberId,
    required String documentId,
    required String uploaderUid,
    required PickedDocument file,
  });

  /// The bytes. Refused by the rules unless a ticket for this caller and this
  /// document was written in the last five minutes.
  Future<Uint8List> read({
    required String householdId,
    required String ownerMemberId,
    required String documentId,
  });

  Future<void> remove({
    required String householdId,
    required String ownerMemberId,
    required String documentId,
  });
}
