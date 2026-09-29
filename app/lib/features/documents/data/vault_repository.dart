import '../../../shared/time/calendar_date.dart';
import '../model/vault_document.dart';
import '../model/vault_grant.dart';
import '../model/vault_view.dart';

/// The metadata of the personal vaults (documents ADR-0002): what is in each,
/// who each is shared with, and who has opened what.
///
/// Every read is one vault at a time, because a vault is a path and the rules
/// decide per path — there is no query across vaults for a rule to refuse
/// half of. Each is bounded (`BE-08`).
abstract interface class VaultRepository {
  Stream<List<VaultDocument>> watchVault({
    required String householdId,
    required String ownerMemberId,
  });

  /// Everybody a vault is shared with. Only its owner and admins may read it.
  Stream<List<VaultGrant>> watchGrants({
    required String householdId,
    required String ownerMemberId,
  });

  /// Whether a vault is shared with [granteeUid] — the one grant document a
  /// grantee may read, and how their app learns a vault is open to them.
  Stream<bool> watchGrantTo({
    required String householdId,
    required String ownerMemberId,
    required String granteeUid,
  });

  /// A vault's view log, newest first. Admins, and the vault's owner.
  Stream<List<VaultView>> watchViews({
    required String householdId,
    required String ownerMemberId,
  });

  /// The id the bytes will be stored under, minted before the upload starts.
  String newDocumentId({
    required String householdId,
    required String ownerMemberId,
  });

  /// Writes the row for bytes that are already stored (`BE-07`).
  Future<void> addDocument(VaultDocumentDraft draft);

  Future<void> editDocument({
    required VaultDocument document,
    required String householdId,
    required String name,
    required List<String> tags,
    required CalendarDate? expiresOn,
  });

  Future<void> removeDocument({
    required String householdId,
    required String ownerMemberId,
    required String documentId,
  });

  Future<void> grant({
    required String householdId,
    required String ownerMemberId,
    required String granteeUid,
    required String granteeMemberId,
    required String grantedBy,
  });

  Future<void> revoke({
    required String householdId,
    required String ownerMemberId,
    required String granteeUid,
  });

  static const documentLimit = 100;
  static const grantLimit = 30;
  static const viewLimit = 100;
}

/// A vault row about to be written, after its bytes are stored.
class VaultDocumentDraft {
  const VaultDocumentDraft({
    required this.householdId,
    required this.ownerMemberId,
    required this.documentId,
    required this.name,
    required this.contentType,
    required this.sizeBytes,
    required this.uploadedBy,
    required this.tags,
    required this.expiresOn,
  });

  final String householdId;
  final String ownerMemberId;
  final String documentId;
  final String name;
  final String contentType;
  final int sizeBytes;
  final String uploadedBy;
  final List<String> tags;
  final CalendarDate? expiresOn;
}
