import 'helper_language.dart';

/// Safety lines a fluent speaker has checked against the English, per
/// language, keyed by the exact English line in `HomeCareSafetyCopy`
/// (home-care ADR-0006).
///
/// **Empty on purpose.** Nobody fluent has reviewed a line yet, and a
/// translation written by whoever wrote the code is not a reviewed one — so
/// every safety line is shown machine-translated, badged as such, with its
/// English beneath. A reviewed line added here loses the badge; the English
/// stays. Adding one needs the reviewer's name in the vault's home-care
/// overview, and the line exactly as the copy file says it.
abstract final class ReviewedSafetyTranslations {
  static const Map<HelperLanguage, Map<String, String>> shipped = {};
}
