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
 */
export const SAM = 'uid-sam';
export const THANDI = 'uid-thandi';
export const SAM_MEMBER = 'm-sam';
export const THANDI_MEMBER = 'm-thandi';

let households = 0;

export async function givenAHouseholdOfTwo(): Promise<string> {
  households += 1;
  const home = `households/h-${String(households)}`;
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
