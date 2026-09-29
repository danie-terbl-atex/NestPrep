import '../../household/model/member.dart';
import 'vault_document.dart';
import 'vault_grant.dart';

/// What the vault screens render: the vaults this person may open, what is in
/// each, and who else each one is shared with (documents ADR-0002).
///
/// Which vaults appear is the same table the rules enforce — the viewer's own,
/// every one for the family, and those granted to them — worked out on the phone
/// only to know which listeners to open. A vault the rules would refuse is
/// never listened to, so nothing here is a copy of a decision the server makes
/// (`FE-04`).
class VaultShelf {
  const VaultShelf({
    required this.owners,
    required this.documents,
    required this.grants,
    required this.managed,
  });

  /// The people whose vaults are open to this viewer, in household order.
  final List<Member> owners;
  final Map<String, List<VaultDocument>> documents;

  /// Who each vault is shared with — only for the vaults the viewer manages.
  final Map<String, List<VaultGrant>> grants;

  /// The vaults this viewer may add to, change and share: their own, and
  /// every one for the family.
  final Set<String> managed;

  bool get isEmpty => owners.isEmpty;

  List<VaultDocument> documentsOf(String memberId) =>
      documents[memberId] ?? const [];

  List<VaultGrant> grantsOf(String memberId) => grants[memberId] ?? const [];

  bool canManage(String memberId) => managed.contains(memberId);

  bool canOpen(String memberId) => owners.any((owner) => owner.id == memberId);

  Member? ownerById(String memberId) =>
      owners.where((owner) => owner.id == memberId).firstOrNull;

  Iterable<VaultDocument> get everyDocument =>
      owners.expand((owner) => documentsOf(owner.id));

  VaultDocument? documentById(String memberId, String documentId) =>
      documentsOf(memberId).where((doc) => doc.id == documentId).firstOrNull;
}
