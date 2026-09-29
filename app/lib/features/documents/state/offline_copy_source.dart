import 'dart:typed_data';

import '../data/document_directory.dart';
import '../data/document_store.dart';
import '../data/vault_store.dart';
import '../model/household_document.dart';
import '../model/offline_copy.dart';
import '../model/vault_document.dart';

/// Where the bytes of a new offline copy come from (documents ADR-0007): a
/// household document straight through the authenticated SDK, a vault
/// document only after `openVaultDocument` has written the vault's log line
/// and issued the ticket — so taking a copy is an open like any other.
final class OfflineCopySource {
  const OfflineCopySource({
    required this.documentStore,
    required this.vaultStore,
    required this.documentDirectory,
    required this.householdId,
  });

  final DocumentStore documentStore;
  final VaultStore vaultStore;
  final DocumentDirectory documentDirectory;
  final String householdId;

  Future<(OfflineCopy, Uint8List)> ofHouseholdDocument(
    HouseholdDocument document, {
    required DateTime now,
  }) async {
    final bytes = await documentStore.read(
      householdId: householdId,
      documentId: document.id,
    );
    return (
      OfflineCopy(
        householdId: householdId,
        documentId: document.id,
        name: document.name,
        contentType: document.contentType,
        sizeBytes: bytes.length,
        savedAt: now,
      ),
      bytes,
    );
  }

  Future<(OfflineCopy, Uint8List)> ofVaultDocument(
    VaultDocument document, {
    required DateTime now,
  }) async {
    await documentDirectory.openVaultDocument(
      householdId: householdId,
      ownerMemberId: document.ownerMemberId,
      documentId: document.id,
    );
    final bytes = await vaultStore.read(
      householdId: householdId,
      ownerMemberId: document.ownerMemberId,
      documentId: document.id,
    );
    return (
      OfflineCopy(
        householdId: householdId,
        ownerMemberId: document.ownerMemberId,
        documentId: document.id,
        name: document.name,
        contentType: document.contentType,
        sizeBytes: bytes.length,
        savedAt: now,
      ),
      bytes,
    );
  }
}
