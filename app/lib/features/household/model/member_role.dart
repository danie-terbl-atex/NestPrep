/// What a member is in a household (household ADR-0003).
///
/// `admin` and `parent` are **family**: they see and do everything, as every
/// member did under ADR-0001, and only `admin` manages people. `kid`, `helper`
/// and `carer` hold a grant per area that an admin chooses.
enum MemberRole {
  admin,
  parent,
  kid,
  helper,
  carer;

  /// Reads the stored name.
  ///
  /// `member` is ADR-0001's family adult, still stored on profiles written
  /// before ADR-0003, and it reads as `parent` — nothing it could do yesterday
  /// is taken away. A name this build has never heard of reads as `carer`: a
  /// restricted role with whatever grant the household records, which is how
  /// the rules treat it too, so the app never shows more than the server
  /// allows (`BE-10`).
  static MemberRole fromName(String name) => switch (name) {
    'member' => MemberRole.parent,
    _ => MemberRole.values.firstWhere(
      (role) => role.name == name,
      orElse: () => MemberRole.carer,
    ),
  };

  bool get isAdmin => this == MemberRole.admin;

  /// Sees and does everything; holds no grant.
  bool get isFamily => this == MemberRole.admin || this == MemberRole.parent;

  /// Holds a grant a parent chooses, area by area.
  bool get isRestricted => !isFamily;

  /// Everything an admin may do that nobody else may (household ADR-0001).
  bool get canManageHousehold => isAdmin;

  /// Whether a profile with this role may sign in on a kid device, while
  /// nobody has claimed it: a `kid`, and only a kid, because a kid device holds
  /// its profile's grant and only a kid has one (accounts ADR-0004). Mirrors
  /// the Functions' `KID_SIGN_IN_ROLES`, which is what enforces it.
  bool get canHaveKidSignIn => this == MemberRole.kid;
}
