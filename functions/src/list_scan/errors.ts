import { HttpsError, type FunctionsErrorCode } from 'firebase-functions/v2/https';

/**
 * Every way reading a shopping list can refuse that is its own (list-scan
 * ADR-0001). Membership refuses with the household's `notAMember`, premium
 * with subscriptions' `premiumRequired` (feature `listScan`), and the model
 * with the shared AI reasons. Same contract as every refusal (BE-04): the
 * app's `ListScanProblem` maps the reason, and `list_scan_contract_test.dart`
 * reads this block.
 */
export const LIST_SCAN_REFUSALS = {
  // The `snapShoppingList` flag is off (foundation ADR-0014).
  listScanOff: ['failed-precondition', 'Reading shopping lists is switched off.'],
  groceriesNotShared: ['permission-denied', 'You cannot add to this grocery list.'],
  listPhotoTooLarge: ['invalid-argument', 'That photo is too large to read.'],
  listPhotoNotSupported: ['invalid-argument', 'That file is not a photo.'],
} as const satisfies Record<string, readonly [FunctionsErrorCode, string]>;

export type ListScanRefusal = keyof typeof LIST_SCAN_REFUSALS;

export function refuseListScan(reason: ListScanRefusal): HttpsError {
  const [code, message] = LIST_SCAN_REFUSALS[reason];
  return new HttpsError(code, message, { reason });
}
