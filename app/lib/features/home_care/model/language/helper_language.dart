/// The languages a helper may read her jobs in (home-care ADR-0006): South
/// Africa's most spoken home languages, and the two most common among helpers
/// from Zimbabwe and Malawi.
///
/// [code] is what is stored and what Cloud Translation takes; the rules and
/// `functions/src/home_care/languages.ts` list the same codes, and
/// `home_care_v2_contract_test.dart` reads all three. [voice] is the
/// locale the phone's speech engine is asked for.
enum HelperLanguage {
  english('en', 'English', 'English', 'en-ZA'),
  afrikaans('af', 'Afrikaans', 'Afrikaans', 'af-ZA'),
  isiZulu('zu', 'isiZulu', 'Zulu', 'zu-ZA'),
  isiXhosa('xh', 'isiXhosa', 'Xhosa', 'xh-ZA'),
  sesotho('st', 'Sesotho', 'Southern Sotho', 'st-ZA'),
  setswana('tn', 'Setswana', 'Tswana', 'tn-ZA'),
  sepedi('nso', 'Sepedi', 'Northern Sotho', 'nso-ZA'),
  xitsonga('ts', 'Xitsonga', 'Tsonga', 'ts-ZA'),
  chiShona('sn', 'chiShona', 'Shona', 'sn-ZW'),
  chichewa('ny', 'Chichewa', 'Chewa', 'ny-MW');

  const HelperLanguage(this.code, this.ownName, this.englishName, this.voice);

  /// The stored code, which Cloud Translation takes as it is.
  final String code;

  /// What speakers call it — shown first, so she can find her own language
  /// without reading English. A proper name, not copy to translate.
  final String ownName;

  /// Its English name, shown beside, for the parent choosing on her behalf.
  final String englishName;

  /// The speech locale asked of the phone for read-aloud.
  final String voice;

  /// Every text is written in English, so English is never translated.
  bool get needsTranslation => this != english;

  /// The language stored under [code]; English for anything this build does
  /// not know, which is what a helper would otherwise have seen (`BE-10`).
  static HelperLanguage fromCode(String? code) =>
      values.where((language) => language.code == code).firstOrNull ?? english;
}
