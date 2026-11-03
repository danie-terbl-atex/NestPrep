import {
  collection,
  deleteDoc,
  doc,
  getDoc,
  getDocs,
  query,
  serverTimestamp,
  setDoc,
  updateDoc,
  where,
} from 'firebase/firestore';
import { beforeEach, describe, expect, it } from 'vitest';

import {
  asKid,
  asSignedOut,
  asUser,
  assertFails,
  assertSucceeds,
  clearData,
  givenData,
  type Firestore,
} from './rules_harness';
import { ROLE_DEFAULTS } from '../../src/household/access';

/**
 * Assistants (assistants ADR-0002, ADR-0003, ADR-0005). The authorization
 * server's root records are closed to every client. A connection is read and
 * deleted — disconnected — by its own member or the family, and written by
 * nobody; activity is read by the member it acted for and the family; the
 * household switch is read by anyone in the household and set by family
 * alone, stamped with who and when. And what an assistant writes carries
 * `createdVia`/`addedVia`, which a client can neither forge nor change, while
 * still editing the event or item as usual.
 */
const SAM = 'uid-sam';
const PAT = 'uid-pat';
const THANDI = 'uid-thandi';
const KID = 'uid-kid-device';
const STRANGER = 'uid-stranger';
const HOUSEHOLD = 'h1';
const HOME = `households/${HOUSEHOLD}`;
const CONNECTIONS = `${HOME}/assistantConnections`;
const ACTIVITY = `${HOME}/assistantActivity`;
const PAT_GRANT = `${HOME}/assistantConnections/g-pat`;
const THANDI_GRANT = `${HOME}/assistantConnections/g-thandi`;
const PAT_LINE = `${HOME}/assistantActivity/a-pat`;
const THANDI_LINE = `${HOME}/assistantActivity/a-thandi`;
const SETTINGS = `${HOME}/assistantSettings/current`;

const connection = (uid: string, memberId: string): Record<string, unknown> => ({
  uid,
  memberId,
  clientId: 'https://claude.ai/oauth/client.json',
  clientName: 'Claude',
  host: 'claude.ai',
  via: 'claude',
  scopes: ['calendar:read'],
  consent: { version: 1, at: new Date() },
  createdAt: new Date(),
  lastUsedAt: null,
  refreshGeneration: 0,
});

const activity = (memberId: string): Record<string, unknown> => ({
  grantId: 'g-pat',
  memberId,
  via: 'claude',
  tool: 'create_event',
  target: { kind: 'event', id: 'e1' },
  at: new Date(),
  expiresAt: new Date(),
});

beforeEach(async () => {
  await clearData();
  await givenData(async (db: Firestore) => {
    await setDoc(doc(db, HOME), {
      name: 'The Parkers',
      timeZone: 'Africa/Johannesburg',
      members: { [SAM]: 'admin', [PAT]: 'parent', [THANDI]: 'helper' },
      access: { [THANDI]: ROLE_DEFAULTS.helper },
      profiles: { [SAM]: 'm-sam', [PAT]: 'm-pat', [THANDI]: 'm-thandi' },
      kids: { [KID]: 'm-kid' },
    });
    for (const [id, role, claimedBy] of [
      ['m-sam', 'admin', SAM],
      ['m-pat', 'parent', PAT],
      ['m-thandi', 'helper', THANDI],
      ['m-kid', 'kid', null],
    ] as const) {
      await setDoc(doc(db, `${HOME}/members/${id}`), {
        displayName: id,
        color: 'mint',
        role,
        claimedBy,
        ...(role === 'kid' ? { access: ROLE_DEFAULTS.kid } : {}),
      });
    }
    await setDoc(doc(db, PAT_GRANT), connection(PAT, 'm-pat'));
    await setDoc(doc(db, THANDI_GRANT), connection(THANDI, 'm-thandi'));
    await setDoc(doc(db, PAT_LINE), activity('m-pat'));
    await setDoc(doc(db, THANDI_LINE), activity('m-thandi'));
    await setDoc(doc(db, SETTINGS), { allowed: true, updatedBy: 'm-sam', updatedAt: new Date() });
    await setDoc(doc(db, `${HOME}/events/by-claude`), {
      title: 'Party',
      note: null,
      date: '2026-11-07',
      startMinute: 600,
      endMinute: 720,
      recurrence: null,
      memberIds: [],
      createdBy: 'm-pat',
      createdAt: new Date(),
      createdVia: 'claude',
    });
    await setDoc(doc(db, `${HOME}/groceryItems/by-claude`), {
      name: 'Milk',
      quantity: '2 l',
      addedBy: 'm-pat',
      addedAt: new Date(),
      boughtAt: null,
      boughtBy: null,
      addedVia: 'claude',
    });
  });
});

describe('the authorization server’s records are closed to every client', () => {
  for (const path of [
    'assistantClients/c1',
    'assistantAuthRequests/r1',
    'assistantCodes/k1',
    'assistantTokens/t1',
  ]) {
    it(path, async () => {
      await givenData(async (db) => {
        await setDoc(doc(db, path), { grantId: 'g-pat', householdId: HOUSEHOLD });
      });
      for (const db of [await asUser(SAM), await asUser(PAT), await asSignedOut()]) {
        await assertFails(getDoc(doc(db, path)));
        await assertFails(setDoc(doc(db, path), { grantId: 'g-mine' }));
        await assertFails(deleteDoc(doc(db, path)));
      }
      await assertFails(getDocs(collection(await asUser(SAM), path.split('/')[0] ?? '')));
    });
  }

  it('and so is the kill switch at appConfig/assistants', async () => {
    await givenData(async (db) => {
      await setDoc(doc(db, 'appConfig/assistants'), { enabled: true });
    });
    await assertFails(getDoc(doc(await asUser(SAM), 'appConfig/assistants')));
    await assertFails(setDoc(doc(await asUser(SAM), 'appConfig/assistants'), { enabled: false }));
  });
});

describe('assistantConnections — the grant, read and disconnected by its member or family', () => {
  it('family reads and lists every connection in the household', async () => {
    const sam = await asUser(SAM);
    await assertSucceeds(getDoc(doc(sam, PAT_GRANT)));
    await assertSucceeds(getDoc(doc(sam, THANDI_GRANT)));
    const listed = await assertSucceeds(getDocs(collection(sam, CONNECTIONS)));
    expect(listed.size).toBe(2);
    await assertSucceeds(getDoc(doc(await asUser(PAT), THANDI_GRANT)));
  });

  it('somebody who is not family reads only their own, and lists only by their own uid', async () => {
    const thandi = await asUser(THANDI);
    await assertSucceeds(getDoc(doc(thandi, THANDI_GRANT)));
    await assertFails(getDoc(doc(thandi, PAT_GRANT)));
    await assertSucceeds(
      getDocs(query(collection(thandi, CONNECTIONS), where('uid', '==', THANDI))),
    );
    await assertFails(getDocs(collection(thandi, CONNECTIONS)));
  });

  it('a stranger, a kid device and nobody read none', async () => {
    for (const db of [
      await asUser(STRANGER),
      await asKid(KID, { householdId: HOUSEHOLD, memberId: 'm-kid' }),
      await asSignedOut(),
    ]) {
      await assertFails(getDoc(doc(db, PAT_GRANT)));
      await assertFails(deleteDoc(doc(db, PAT_GRANT)));
    }
  });

  it('its member disconnects it; family disconnects anybody’s', async () => {
    await assertSucceeds(deleteDoc(doc(await asUser(THANDI), THANDI_GRANT)));
    await assertFails(deleteDoc(doc(await asUser(THANDI), PAT_GRANT)));
    await assertSucceeds(deleteDoc(doc(await asUser(SAM), PAT_GRANT)));
  });

  it('no client creates one or changes one — not even to widen its own scopes', async () => {
    const pat = await asUser(PAT);
    await assertFails(setDoc(doc(pat, `${CONNECTIONS}/g-new`), connection(PAT, 'm-pat')));
    await assertFails(updateDoc(doc(pat, PAT_GRANT), { scopes: ['calendar:read', 'lists:write'] }));
    await assertFails(updateDoc(doc(await asUser(SAM), PAT_GRANT), { lastUsedAt: new Date() }));
  });
});

describe('assistantActivity — what an assistant did, for its member and the family', () => {
  it('family reads every line', async () => {
    const sam = await asUser(SAM);
    await assertSucceeds(getDoc(doc(sam, THANDI_LINE)));
    await assertSucceeds(getDocs(collection(sam, ACTIVITY)));
  });

  it('a member who is not family reads only what was done as them', async () => {
    const thandi = await asUser(THANDI);
    await assertSucceeds(getDoc(doc(thandi, THANDI_LINE)));
    await assertFails(getDoc(doc(thandi, PAT_LINE)));
    await assertSucceeds(
      getDocs(query(collection(thandi, ACTIVITY), where('memberId', '==', 'm-thandi'))),
    );
  });

  it('a kid device, a stranger and nobody read none', async () => {
    for (const db of [
      await asKid(KID, { householdId: HOUSEHOLD, memberId: 'm-kid' }),
      await asUser(STRANGER),
      await asSignedOut(),
    ]) {
      await assertFails(getDoc(doc(db, PAT_LINE)));
    }
  });

  it('no client writes a line, edits one or deletes one', async () => {
    const sam = await asUser(SAM);
    await assertFails(setDoc(doc(sam, `${ACTIVITY}/forged`), activity('m-sam')));
    await assertFails(updateDoc(doc(sam, PAT_LINE), { tool: 'delete_event' }));
    await assertFails(deleteDoc(doc(sam, PAT_LINE)));
  });
});

describe('assistantSettings/current — the household’s own switch', () => {
  const flip = (
    updatedBy: string,
    extra: Record<string, unknown> = {},
  ): Record<string, unknown> => ({
    allowed: false,
    updatedBy,
    updatedAt: serverTimestamp(),
    ...extra,
  });

  it('anybody in the household reads it, a kid device included; a stranger does not', async () => {
    await assertSucceeds(getDoc(doc(await asUser(THANDI), SETTINGS)));
    await assertSucceeds(
      getDoc(doc(await asKid(KID, { householdId: HOUSEHOLD, memberId: 'm-kid' }), SETTINGS)),
    );
    await assertFails(getDoc(doc(await asUser(STRANGER), SETTINGS)));
    await assertFails(getDoc(doc(await asSignedOut(), SETTINGS)));
  });

  it('family sets it, as themselves, at the server’s time', async () => {
    await assertSucceeds(setDoc(doc(await asUser(PAT), SETTINGS), flip('m-pat')));
    await assertSucceeds(
      updateDoc(doc(await asUser(SAM), SETTINGS), {
        allowed: true,
        updatedBy: 'm-sam',
        updatedAt: serverTimestamp(),
      }),
    );
  });

  it('is created by family when it was never set', async () => {
    await givenData(async (db) => {
      await deleteDoc(doc(db, SETTINGS));
    });
    await assertSucceeds(setDoc(doc(await asUser(SAM), SETTINGS), flip('m-sam')));
  });

  it('nobody else sets it, and no shape but its own is accepted', async () => {
    const sam = await asUser(SAM);
    await assertFails(setDoc(doc(await asUser(THANDI), SETTINGS), flip('m-thandi')));
    await assertFails(
      setDoc(
        doc(await asKid(KID, { householdId: HOUSEHOLD, memberId: 'm-kid' }), SETTINGS),
        flip('m-kid'),
      ),
    );
    await assertFails(setDoc(doc(sam, SETTINGS), flip('m-pat')));
    await assertFails(setDoc(doc(sam, SETTINGS), flip('m-sam', { updatedAt: new Date() })));
    await assertFails(setDoc(doc(sam, SETTINGS), flip('m-sam', { allowed: 'no' })));
    await assertFails(setDoc(doc(sam, SETTINGS), flip('m-sam', { scopes: [] })));
    await assertFails(
      setDoc(doc(sam, SETTINGS), { updatedBy: 'm-sam', updatedAt: serverTimestamp() }),
    );
    await assertFails(setDoc(doc(sam, `${HOME}/assistantSettings/other`), flip('m-sam')));
    await assertFails(deleteDoc(doc(sam, SETTINGS)));
  });
});

describe('what an assistant wrote says so, and only an assistant can say it', () => {
  const EVENT = `${HOME}/events/by-claude`;
  const ITEM = `${HOME}/groceryItems/by-claude`;

  it('a client cannot create an event or an item claiming an assistant made it', async () => {
    const pat = await asUser(PAT);
    await assertFails(
      setDoc(doc(pat, `${HOME}/events/forged`), {
        title: 'Party',
        date: '2026-11-07',
        startMinute: null,
        endMinute: null,
        memberIds: [],
        createdBy: 'm-pat',
        createdAt: serverTimestamp(),
        createdVia: 'claude',
      }),
    );
    await assertFails(
      setDoc(doc(pat, `${HOME}/groceryItems/forged`), {
        name: 'Bread',
        quantity: null,
        addedBy: 'm-pat',
        addedAt: serverTimestamp(),
        boughtAt: null,
        boughtBy: null,
        addedVia: 'chatgpt',
      }),
    );
  });

  it('nor change or drop the mark on one an assistant made', async () => {
    const pat = await asUser(PAT);
    await assertFails(updateDoc(doc(pat, EVENT), { createdVia: 'chatgpt' }));
    await assertFails(
      setDoc(doc(pat, EVENT), {
        title: 'Party',
        note: null,
        date: '2026-11-07',
        startMinute: 600,
        endMinute: 720,
        recurrence: null,
        memberIds: [],
        createdBy: 'm-pat',
        createdAt: new Date(),
      }),
    );
    await assertFails(updateDoc(doc(pat, ITEM), { addedVia: 'assistant' }));
  });

  it('and still edits it the way the app does, keeping the mark', async () => {
    const pat = await asUser(PAT);
    await assertSucceeds(updateDoc(doc(pat, EVENT), { title: 'Emma’s party', startMinute: 660 }));
    await assertSucceeds(updateDoc(doc(await asUser(SAM), EVENT), { note: 'Bring a gift' }));
    await assertSucceeds(updateDoc(doc(pat, ITEM), { name: 'Full cream milk', quantity: '1 l' }));
    await assertSucceeds(
      updateDoc(doc(await asUser(SAM), ITEM), { boughtAt: serverTimestamp(), boughtBy: 'm-sam' }),
    );
    const event = await getDoc(doc(pat, EVENT));
    expect(event.get('createdVia')).toBe('claude');
  });
});
