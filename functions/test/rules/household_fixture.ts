import { randomUUID } from 'node:crypto';

import { doc, setDoc } from 'firebase/firestore';

import { givenData, type Firestore } from './rules_harness';

/**
 * A household with two real members, for the tests that need two signed-in
 * clients rather than one allowed-and-denied pair.
 *
 * Every call gets a household id of its own. `clearFirestore` empties the
 * emulator but not the SDK's local cache, and a rules-test context is reused
 * for a uid — so a document from an earlier test can still be sitting in a
 * client's cache when the next one opens a listener. A path nobody has used
 * before cannot collide with it.
 *
 * The id carries a token for the file that made it, not only a counter: the
 * counter starts again in every test file, and two files that both used
 * `h-1` — liveness and offline, which clear nothing — met in the same
 * household whenever vitest ran them in the other order, and a queued offline
 * write from one refused the next file's first writes.
 */
export const SAM = 'uid-sam';
export const THANDI = 'uid-thandi';
export const SAM_MEMBER = 'm-sam';
export const THANDI_MEMBER = 'm-thandi';

let households = 0;
const run = randomUUID().slice(0, 8);

export async function givenAHouseholdOfTwo(): Promise<string> {
  households += 1;
  const home = `households/h-${run}-${String(households)}`;
  await givenData(async (db: Firestore) => {
    await setDoc(doc(db, home), {
      name: 'The Parkers',
      timeZone: 'Africa/Johannesburg',
      members: { [SAM]: 'admin', [THANDI]: 'helper' },
    });
    for (const [id, name, role, claimedBy] of [
      [SAM_MEMBER, 'Sam', 'admin', SAM],
      [THANDI_MEMBER, 'Thandi', 'helper', THANDI],
    ] as const) {
      await setDoc(doc(db, `${home}/members/${id}`), {
        displayName: name,
        color: 'violet',
        role,
        claimedBy,
      });
    }
  });
  return home;
}
