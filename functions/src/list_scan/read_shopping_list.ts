import { logger } from 'firebase-functions/v2';
import { onCall } from 'firebase-functions/v2/https';

import { aiRuntime } from '../ai/ai_runtime';
import { runAiCall } from '../ai/run_ai_call';
import { tierFrom } from '../ai/usage_rules';
import { parseInput, requireUid } from '../household/parse_input';
import { db } from '../shared/firestore';
import { readFlag } from '../shared/feature_flags';
import { premiumRequired } from '../subscriptions/errors';
import { entitlementRef } from '../subscriptions/subscription_documents';
import { refuseListScan } from './errors';
import { listCallerIn } from './list_caller';
import { checkedListPhoto } from './list_photo';
import { listRequest } from './list_prompt';
import { linesFrom, listReply, type ListLine } from './list_reply';
import { readShoppingListInput } from './schemas';

export interface ReadShoppingListResult {
  readonly lines: ListLine[];
  readonly callsLeft: number;
}

/**
 * A photo of a shopping list becomes proposed grocery lines (list-scan
 * ADR-0001). **Nothing is written here**: the member ticks and edits the lines
 * in the app, which adds them to the list as items they typed, under the
 * ordinary grocery rules. The photo lives for this request only.
 *
 * Who may: anybody the `groceries` grant lets add to the list, in a premium
 * household — checked here, not only on the phone. One of the household's
 * monthly AI calls, through `runAiCall` (foundation ADR-0015).
 */
export const readShoppingList = onCall(
  { timeoutSeconds: 60, memory: '512MiB' },
  async (request): Promise<ReadShoppingListResult> => {
    const uid = requireUid(request.auth);
    const input = parseInput(readShoppingListInput, request.data);
    const store = db();

    if (!(await readFlag(store, 'snapShoppingList'))) throw refuseListScan('listScanOff');
    const caller = await listCallerIn(store, input.householdId, uid);
    const entitlement = await entitlementRef(store, input.householdId).get();
    if (tierFrom(entitlement.data(), new Date()) !== 'premium') {
      throw premiumRequired('listScan');
    }
    const photo = checkedListPhoto(input.mimeType, input.data);

    const result = await runAiCall(await aiRuntime(store), {
      feature: 'listScan',
      householdId: input.householdId,
      timeZone: caller.timeZone,
      uid,
      request: listRequest(input.mimeType, photo),
      schema: listReply,
    });
    const lines = linesFrom(result.value);

    // Counts only: never an item the list named (ENG-22).
    logger.info('shopping list read', {
      householdId: input.householdId,
      mimeType: input.mimeType,
      itemsRead: result.value.items.length,
      proposed: lines.length,
    });
    return { lines, callsLeft: result.callsLeft };
  },
);
