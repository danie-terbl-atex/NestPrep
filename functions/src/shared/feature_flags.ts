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
  'documentShareLinks',
  'documentOfflineCopies',
  // lunch-box V2 (lunch-box ADR-0005 to ADR-0007) — client-side switches; the
  // rules hold a kid to approved options and budget writes to premium
  // whatever they say.
  'lunchPantry',
  'lunchBudget',
  'lunchKidPicks',
  // ---- home care V2 (home-care ADR-0004 to ADR-0006) ----
  'homeCareRoutines',
  'homeCareStock',
  'homeCareHelperLanguage',
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
