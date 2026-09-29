/// The version this build says it is, on the About screen.
///
/// A constant rather than a platform-channel read, so no package is added for
/// two numbers (`ENG-17`). `pubspec.yaml`'s `version:` is what the stores see;
/// `app_version_test.dart` fails the build when the two disagree, so raise
/// both in the same change.
abstract final class AppVersion {
  static const name = '0.9.0';
  static const build = 2;
}
