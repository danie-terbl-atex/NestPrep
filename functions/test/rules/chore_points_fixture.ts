import { doc, serverTimestamp, setDoc } from 'firebase/firestore';

import { DATE, HOME, LEO, MIA, givenAKidsHousehold } from './kid_fixture';
import { clearData, givenData, type Firestore } from './rules_harness';

/**
 * What the two chore-points rules suites share (todos ADR-0003): the kid
 * household, with a balance, a ledger line, a pending claim and a waiting
 * request for Mia and Leo each, a reward on the shelf, a chore Thandi made
 * and a starred one Sam made — each written with the rules off.
 */

export const STARS = {
  balances: `${HOME}/pointBalances`,
  entries: `${HOME}/pointEntries`,
  claims: `${HOME}/pointClaims`,
  rewards: `${HOME}/rewards`,
  requests: `${HOME}/rewardRequests`,
};

export function starredChore(overrides: Record<string, unknown> = {}): Record<string, unknown> {
  return {
    title: 'Tidy your room',
    note: null,
    dueDate: DATE,
    recurrence: null,
    assigneeIds: [MIA],
    createdBy: 'm-sam',
    routineId: null,
    createdAt: serverTimestamp(),
    points: 5,
    needsApproval: true,
    ...overrides,
  };
}

export function request(overrides: Record<string, unknown> = {}): Record<string, unknown> {
  return {
    rewardId: 'ice-cream',
    memberId: MIA,
    requestedBy: MIA,
    requestedAt: serverTimestamp(),
    ...overrides,
  };
}

export function reward(overrides: Record<string, unknown> = {}): Record<string, unknown> {
  return {
    title: 'Movie night',
    cost: 30,
    icon: 'movie',
    createdBy: 'm-sam',
    createdAt: serverTimestamp(),
    ...overrides,
  };
}

export async function givenStars(): Promise<void> {
  await clearData();
  await givenAKidsHousehold();
  await givenData(async (db: Firestore) => {
    for (const member of [MIA, LEO]) {
      await setDoc(doc(db, `${STARS.balances}/${member}`), {
        memberId: member,
        balance: 12,
        earned: 12,
        spent: 0,
        streakDays: 2,
        bestStreak: 2,
        streakLastDay: DATE,
      });
      await setDoc(doc(db, `${STARS.entries}/chore_${member}`), {
        memberId: member,
        delta: 12,
        kind: 'chore',
        sourceId: 'x',
        title: 'Dishes',
        at: new Date(),
      });
      await setDoc(doc(db, `${STARS.claims}/claim_${member}`), {
        memberId: member,
        taskId: 'dishes',
        occurrenceDate: DATE,
        title: 'Dishes',
        points: 3,
        status: 'pending',
        round: 1,
      });
      await setDoc(doc(db, `${STARS.requests}/req_${member}`), {
        rewardId: 'ice-cream',
        memberId: member,
        requestedBy: member,
        requestedAt: new Date(),
        status: 'waiting',
        cost: 10,
      });
    }
    await setDoc(doc(db, `${STARS.rewards}/ice-cream`), {
      title: 'Ice cream',
      cost: 10,
      icon: 'iceCream',
      createdBy: 'm-sam',
      createdAt: new Date(),
    });
    // A chore Thandi (a helper with the legacy `edit` grant) made herself.
    await setDoc(doc(db, `${HOME}/tasks/thandi-chore`), {
      ...starredChore({ points: 0, needsApproval: false, createdBy: 'm-thandi' }),
      createdAt: new Date(),
    });
    await setDoc(doc(db, `${HOME}/tasks/starred`), {
      ...starredChore(),
      createdAt: new Date(),
    });
  });
}
