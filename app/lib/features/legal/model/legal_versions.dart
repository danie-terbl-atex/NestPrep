/// The versions of the two documents this build asks people to accept
/// (accounts ADR-0005). Raise one in the same change that raises the
/// `version:` of its document — `legal_versions_test.dart` fails until both
/// agree — and every signed-in account is asked again on its next open.
abstract final class LegalVersions {
  static const int terms = 1;
  static const int privacy = 1;
}
