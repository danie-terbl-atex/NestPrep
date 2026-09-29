import '../../household/model/member_role.dart';

/// Whether a role is family for the vaults: family reads and manages every
/// vault, because household ADR-0003 keeps per-item privacy between family
/// members out of v1 (documents ADR-0002). `member` is read as `parent` there.
///
/// The same list is in `firestore.rules`, `storage.rules` and
/// `functions/src/documents/vault_access.ts` as `['admin', 'parent', 'member']`;
/// this build's `MemberRole` has no `parent` yet, and the unknown name reads as
/// `member`, which is family.
bool isVaultFamily(MemberRole? role) =>
    role == MemberRole.admin || role == MemberRole.member;
