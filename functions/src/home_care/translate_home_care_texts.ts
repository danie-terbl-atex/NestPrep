import type { Firestore } from 'firebase-admin/firestore';
import { logger } from 'firebase-functions/v2';
import { onCall } from 'firebase-functions/v2/https';

import { householdRef } from '../household/documents';
import { parseInput, requireUid } from '../household/parse_input';
import { fetchHttpClient } from '../shared/http_client';
import { readFlag, runsInEmulator } from '../shared/feature_flags';
import { db } from '../shared/firestore';
import { ApplicationDefaultTranslationToken, CloudTranslator } from './cloud_translator';
import { EmulatorTranslator } from './emulator_translator';
import { refuseHomeCare } from './errors';
import { isOffShift } from '../household/shift_window';
import { homeCareReaderFrom } from './home_care_caller';
import type { TargetLanguage } from './languages';
import { translateHomeCareTextsInput } from './schemas';
import { cacheTranslations, readCachedTranslations, type Translations } from './translation_cache';
import { charactersOf } from './translation_cap';
import { claimCharacters, refundCharacters } from './translation_ledger';
import type { Translator } from './translator';

/** Google in the cloud; a marker under the emulator, so nothing local bills. */
function translatorHere(): Translator {
  return runsInEmulator()
    ? new EmulatorTranslator()
    : new CloudTranslator(
        fetchHttpClient,
        new ApplicationDefaultTranslationToken(),
        process.env['GCLOUD_PROJECT'] ?? '',
      );
}

/**
 * The texts the cache did not have: claimed against the month, sent, stored,
 * and refunded if Google could not do it (BE-06, BE-09).
 */
async function translateMissing(
  store: Firestore,
  householdId: string,
  language: TargetLanguage,
  missing: readonly string[],
): Promise<Translations> {
  const characters = charactersOf(missing);
  const month = await claimCharacters(store, householdId, characters, new Date());
  const translator = translatorHere();
  const outcome = await translator.translate(missing, language);
  if (outcome.kind !== 'translated') {
    await refundCharacters(store, householdId, month, characters);
    logger.warn('home care translation failed', {
      householdId,
      language,
      outcome: outcome.kind,
      reason: outcome.kind === 'unavailable' ? outcome.reason : null,
    });
    throw refuseHomeCare(
      outcome.kind === 'unsupported' ? 'languageUnsupported' : 'translationUnavailable',
    );
  }
  const fresh: Translations = Object.fromEntries(
    missing.map((text, index) => [text, outcome.texts[index] ?? text]),
  );
  await cacheTranslations(store, householdId, language, fresh, translator.engine);
  return fresh;
}

/**
 * A job's steps, its safety and a routine's items in the helper's language
 * (home-care ADR-0006).
 *
 * A Function rather than the phone because the translation service is paid
 * for from the household's monthly cap, which only a server can hold, and
 * reached as the Functions' own service account, which no phone may be. Each
 * text is translated once per language: the cache is read first, only what is
 * missing is claimed, sent and stored — for every later ask, the phone's own
 * offline copy included.
 */
export const translateHomeCareTexts = onCall(async (request) => {
  const uid = requireUid(request.auth);
  const input = parseInput(translateHomeCareTextsInput, request.data);
  const store = db();

  const household = await householdRef(store, input.householdId).get();
  if (!household.exists) throw refuseHomeCare('notAMember');
  homeCareReaderFrom(household.data(), uid);
  // A shift-only carer off shift holds no home care (nanny-hub ADR-0006).
  if (await isOffShift(store, input.householdId, household.data(), uid, new Date())) {
    throw refuseHomeCare('homeCareNotShared');
  }
  if (!(await readFlag(store, 'homeCareHelperLanguage'))) {
    throw refuseHomeCare('translationSwitchedOff');
  }

  const found = await readCachedTranslations(store, input.householdId, input.texts, input.language);
  const missing = input.texts.filter((text) => !Object.hasOwn(found, text));
  if (missing.length > 0) {
    Object.assign(found, await translateMissing(store, input.householdId, input.language, missing));
  }

  // Counts only — never a text, which is a household's own words (ENG-22).
  logger.info('home care texts translated', {
    householdId: input.householdId,
    language: input.language,
    asked: input.texts.length,
    translatedNow: missing.length,
  });
  return {
    translations: input.texts.map((text) => ({ text, translated: found[text] ?? text })),
  };
});
