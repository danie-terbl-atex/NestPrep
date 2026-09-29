import type { Firestore } from 'firebase-admin/firestore';

/**
 * The switches for V2 capabilities (foundation ADR-0014), as the server reads
 * them: one document, `appConfig/flags`, one boolean per capability. The app's
 * `lib/shared/flags/feature_flag.dart` names the same fields, and
 * `feature_flags.test.ts` reads both.
 *
 * An absent field is ON under the emulator and OFF in the cloud — the same
 * rule the app applies with debug and release — so a V2 capability ships dark
 * until Daniel sets it, and an explicit `false` is the kill switch everywhere.
 */
export const APP_CONFIG = 'appConfig';
export const FLAGS_DOCUMENT = 'flags';

export const FEATURE_FLAGS = [
  // ---- documents V2 (documents ADR-0006, ADR-0007) ----
  'documentShareLinks',
  'documentOfflineCopies',
  // ---- calendar V2 (calendar ADR-0005, ADR-0006) ----
  'snapSchoolLetter',
  'mentalLoadView',
  // ---- two homes (household ADR-0004) ----
  'coParenting',
  // ---- nanny hub V2 (nanny-hub ADR-0004 to ADR-0007) ----
  'nannyPhotoUpdates',
  'nannyPickups',
  'nannyShiftOnly',
  'nannyOffline',
  // ---- referrals: give a month, get a month (subscriptions ADR-0002) ----
  'referralRewards',
] as const;
export type FeatureFlag = (typeof FEATURE_FLAGS)[number];

/** Whether [flag] is on, given the stored document (or none) and where this runs. */
export function flagIsOn(
  stored: Readonly<Record<string, unknown>> | undefined,
  flag: FeatureFlag,
  isEmulator: boolean,
): boolean {
  const value = stored?.[flag];
  return typeof value === 'boolean' ? value : isEmulator;
}

export function runsInEmulator(): boolean {
  return process.env['FUNCTIONS_EMULATOR'] === 'true';
}

export async function readFlag(store: Firestore, flag: FeatureFlag): Promise<boolean> {
  const snapshot = await store.collection(APP_CONFIG).doc(FLAGS_DOCUMENT).get();
  return flagIsOn(snapshot.data(), flag, runsInEmulator());
}
