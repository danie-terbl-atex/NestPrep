/// What a member may do (household ADR-0001). In v1 `member` and `helper` have
/// identical permissions; the distinction exists so a later phase can gate on it
/// without a migration.
enum MemberRole {
  admin,
  member,
  helper;

  /// Reads the stored name, defaulting rather than throwing: a role added by a
  /// later build must not stop this one from showing the household (`BE-10`).
  static MemberRole fromName(String name) => MemberRole.values.firstWhere(
    (role) => role.name == name,
    orElse: () => MemberRole.member,
  );

  bool get isAdmin => this == MemberRole.admin;

  /// Everything an admin may do that nobody else may (household ADR-0001).
  bool get canManageHousehold => isAdmin;
}
