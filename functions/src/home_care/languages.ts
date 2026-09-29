/**
 * The languages a helper may choose (home-care ADR-0006), as the codes Cloud
 * Translation takes. English is the language every text is written in, so it
 * is never a target. The app's `HelperLanguage` and the rules'
 * `homeCareHelpers` list name the same codes, and
 * `home_care_v2_contract_test.dart` reads all three.
 */
export const HELPER_LANGUAGES = [
  'en',
  'af',
  'zu',
  'xh',
  'st',
  'tn',
  'nso',
  'ts',
  'sn',
  'ny',
] as const;
export type HelperLanguage = (typeof HELPER_LANGUAGES)[number];

export const SOURCE_LANGUAGE = 'en';

export const TARGET_LANGUAGES = ['af', 'zu', 'xh', 'st', 'tn', 'nso', 'ts', 'sn', 'ny'] as const;
export type TargetLanguage = (typeof TARGET_LANGUAGES)[number];
