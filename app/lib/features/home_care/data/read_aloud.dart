import '../model/language/helper_language.dart';

/// Whether this phone can speak a language (home-care ADR-0006).
enum VoiceSupport {
  /// A voice for the language is on the phone.
  available,

  /// No voice for it, but an English one: the English original is read.
  englishOnly,

  /// No speech engine answering at all.
  none,
}

/// The phone's own speech engine, behind an interface so no test speaks and
/// the plugin can be replaced (home-care ADR-0006, `ENG-17`). Nothing leaves
/// the phone to be spoken.
abstract interface class ReadAloud {
  /// What reading [language] aloud would do on this phone.
  Future<VoiceSupport> supportFor(HelperLanguage language);

  /// Speaks [text] in [voice], stopping whatever was being read, and
  /// completes when it has finished or been stopped — false when the engine
  /// refused, which the screen then explains.
  Future<bool> speak(String text, HelperLanguage voice);

  Future<void> stop();
}
