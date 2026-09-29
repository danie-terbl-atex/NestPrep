import { logger } from 'firebase-functions/v2';
import { onCall } from 'firebase-functions/v2/https';

import { aiRuntime } from '../ai/ai_runtime';
import { runAiCall } from '../ai/run_ai_call';
import { callerIn } from '../calendar_sync/caller_access';
import { parseInput, requireUid } from '../household/parse_input';
import { db } from '../shared/firestore';
import { readFlag } from '../shared/feature_flags';
import { readChildHints } from './child_hints';
import { refuseLetter } from './errors';
import { checkedLetter } from './letter_file';
import { letterRequest } from './letter_prompt';
import { letterReply, proposalsFrom, type LetterProposal } from './letter_reply';
import { todayIn } from './plain_date';
import { readSchoolLetterInput } from './schemas';

export interface ReadSchoolLetterResult {
  readonly proposals: LetterProposal[];
  readonly callsLeft: number;
}

/**
 * A photo or PDF of a school letter becomes proposed calendar events
 * (calendar ADR-0005). **Nothing is written to the calendar here**: the
 * proposals go back to the app, where the parent ticks, edits and confirms
 * each one, and the app saves them as ordinary events under the ordinary
 * rules. The letter itself is never stored; it lives for this request.
 *
 * Who may: anybody the household's `calendar` grant lets add events — the
 * same `edit` the rules ask of an event write. The model is reached only
 * through `runAiCall`, which holds the kill switch, the monthly cap and the
 * usage ledger (foundation ADR-0015).
 *
 * Sixty seconds and 512 MiB rather than the callables' thirty and 256: a
 * model reading a page takes seconds, and the letter is held in memory
 * twice, as base64 and as bytes (BE-19).
 */
export const readSchoolLetter = onCall(
  { timeoutSeconds: 60, memory: '512MiB' },
  async (request): Promise<ReadSchoolLetterResult> => {
    const uid = requireUid(request.auth);
    const input = parseInput(readSchoolLetterInput, request.data);
    const store = db();

    if (!(await readFlag(store, 'snapSchoolLetter'))) throw refuseLetter('letterFeatureOff');
    const caller = await callerIn(store, input.householdId, uid, 'edit');
    const letter = checkedLetter(input.mimeType, input.data);

    const [children, deps] = await Promise.all([
      readChildHints(store, input.householdId),
      aiRuntime(store),
    ]);
    const { today, weekday } = todayIn(caller.timeZone, deps.now());

    const result = await runAiCall(deps, {
      feature: 'schoolLetter',
      householdId: input.householdId,
      timeZone: caller.timeZone,
      uid,
      request: letterRequest({
        today,
        weekday,
        children,
        mimeType: input.mimeType,
        base64: letter,
      }),
      schema: letterReply,
    });
    const proposals = proposalsFrom(result.value, today, children);

    // Counts only: never a title, a date or anything the letter said (ENG-22).
    logger.info('school letter read', {
      householdId: input.householdId,
      mimeType: input.mimeType,
      eventsRead: result.value.events.length,
      proposed: proposals.length,
      childrenHinted: children.length,
    });
    return { proposals, callsLeft: result.callsLeft };
  },
);
