import type { Firestore } from 'firebase-admin/firestore';

import { VAULTS, VAULT_DOCUMENTS } from '../documents/vault_refs';
import { householdRef } from '../household/documents';
import type { ExpiringDocument, HouseholdDay } from './digest_facts';
import {
  readApprovals,
  readChores,
  readEvents,
  readExpiring,
  readLunchBoxes,
  readShifts,
} from './digest_reads';
import type { HouseholdRoster } from './household_roster';
import { canSee, type Recipient } from './recipients';

/**
 * One household's day for the people due a digest in it (notifications
 * ADR-0002). An area is read only when somebody due this morning may see it,
 * so a household whose only early riser is a helper who cleans reads its
 * cleaning jobs and nothing else — the fewest reads, and nothing loaded that
 * the composer would then have to remember not to show.
 */
export interface DayRequest {
  readonly store: Firestore;
  readonly roster: HouseholdRoster;
  readonly today: string;
  readonly now: Date;
  readonly due: readonly Recipient[];
}

const NOTHING = Promise.resolve([]);

export async function loadHouseholdDay(request: DayRequest): Promise<HouseholdDay> {
  const { store, roster, today, now, due } = request;
  const home = householdRef(store, roster.householdId);
  const anyone = (test: (recipient: Recipient) => boolean): boolean => due.some(test);

  const withAccount = due.filter((recipient) => recipient.hasAccount);
  const [events, lunchBoxes, chores, documents, vaultLists, shifts, approvals] = await Promise.all([
    anyone((r) => canSee(r, 'calendar')) ? readEvents(home, today) : NOTHING,
    anyone((r) => r.levels.lunch !== 'none') ? readLunchBoxes(home, today) : NOTHING,
    anyone((r) => r.levels.todos !== 'none') ? readChores(home, today) : NOTHING,
    anyone((r) => canSee(r, 'documents'))
      ? readExpiring(home.collection('documents'), today)
      : NOTHING,
    Promise.all(
      withAccount.map((recipient) =>
        readExpiring(
          home.collection(VAULTS).doc(recipient.memberId).collection(VAULT_DOCUMENTS),
          today,
        ),
      ),
    ),
    anyone((r) => canSee(r, 'nannyHub'))
      ? readShifts(home, now)
      : Promise.resolve({ openShifts: [], handovers: [] }),
    anyone((r) => r.isFamily)
      ? readApprovals(home)
      : Promise.resolve({ choresToCheck: 0, rewardsAskedFor: 0 }),
  ]);

  const vaults: Record<string, readonly ExpiringDocument[]> = Object.fromEntries(
    withAccount.map((recipient, index) => [recipient.memberId, vaultLists[index] ?? []]),
  );
  return {
    today,
    zone: roster.zone,
    names: roster.names,
    events,
    lunchBoxes,
    chores,
    documents,
    vaults,
    ...shifts,
    ...approvals,
  };
}
