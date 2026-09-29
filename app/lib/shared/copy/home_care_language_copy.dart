import '../../features/home_care/data/read_aloud.dart';
import '../../features/home_care/model/language/helper_language.dart';

/// Every word the helper's language and read-aloud say (home-care ADR-0006,
/// `FE-19`) — exported through `home_care_copy.dart`. The languages' own
/// names are proper names on `HelperLanguage`, not copy.
abstract final class HomeCareLanguageCopy {
  static const languages = 'Languages';
  static const languagesSubtitle = 'Who reads their jobs in which language';
  static const myLanguage = 'My language';
  static const myLanguageSubtitle =
      'Your jobs, steps and safety in the language you read best';
  static const yourLanguage = 'You';
  static const helpersHeading = 'Helpers';
  static const chooseLanguage = 'Choose a language';
  static const notChosen = 'English — not chosen yet';
  static String names(String own, String english) =>
      own == english ? own : '$own · $english';
  static const tryItHeading = 'Try it';
  static const sampleLine = 'Open a window before you start cleaning.';

  static String showing(HelperLanguage language) =>
      'Showing ${language.ownName}';

  static const machineTranslated = 'Machine translated';
  static const reviewed = 'Checked by a speaker';
  static const showEnglish = 'Show English too';
  static const hideEnglish = 'Hide English';
  static String inEnglish(String text) => 'In English: $text';
  static const translating = 'Translating…';
  static const safetyStaysInEnglish =
      'Safety is shown in English as well, because a wrong word here can hurt '
      'somebody. If anything is unclear, ask before you start.';

  static const readAloud = 'Read aloud';
  static const stopReading = 'Stop reading';
  static String readAloudFor(String text) => 'Read aloud: $text';
  static String stopReadingFor(String text) => 'Stop reading: $text';

  static String voice(VoiceSupport support, HelperLanguage language) =>
      switch (support) {
        VoiceSupport.available => 'Reads aloud in ${language.ownName}.',
        VoiceSupport.englishOnly =>
          'This phone has no ${language.ownName} voice, so it reads the '
              'English. Add one in the phone’s settings under text-to-speech.',
        VoiceSupport.none => 'This phone cannot read aloud.',
      };
}
