import { getApps, initializeApp } from 'firebase-admin/app';
import { getFirestore, type Firestore as AdminFirestore } from 'firebase-admin/firestore';
import {
  deleteDoc,
  deleteField,
  doc,
  serverTimestamp,
  setDoc,
  updateDoc,
} from 'firebase/firestore';
import { beforeEach, describe, it } from 'vitest';

import type { AssistantPrincipal } from '../../src/assistants/principal';
import { deleteEvent } from '../../src/assistants/mcp/tools/change_event';
import { createEvent } from '../../src/assistants/mcp/tools/create_event';
import { addGroceryItems, tickGroceryItems } from '../../src/assistants/mcp/tools/groceries';
import { weeklyOn } from '../recurrence_shape';
import {
  FIRESTORE_AT,
  asUser,
  assertFails,
  assertSucceeds,
  clearData,
  givenData,
  type Firestore,
} from './rules_harness';

/**
 * What an assistant writes, held to the rules the app's own writes meet
 * (assistants ADR-0005): the documents `create_event` and
 * `add_grocery_items` make through the Admin SDK are edited, ticked and
 * deleted by a member's app afterwards exactly as their own would be, and
 * `createdVia` / `addedVia` can be neither forged on a client's create nor
 * changed or dropped by a client's edit.
 */

const HOUSEHOLD = 'h-prov';
const SAM = 'uid-sam';
const PAT = 'uid-pat';
const SAM_MEMBER = 'm-sam';
const PAT_MEMBER = 'm-pat';
const EVENTS = `households/${HOUSEHOLD}/events`;
const ITEMS = `households/${HOUSEHOLD}/groceryItems`;
const SKIPS = `households/${HOUSEHOLD}/eventExceptions`;
const NOW = new Date('2026-10-29T08:00:00Z');

const sam: AssistantPrincipal = {
  grantId: 'grant-sam',
  uid: SAM,
  householdId: HOUSEHOLD,
  via: 'claude',
  scopes: ['household:read', 'calendar:read', 'calendar:write', 'lists:read', 'lists:write'],
};

/** The Functions' own view of the same emulator: the Admin SDK, rules skipped. */
function server(): AdminFirestore {
  process.env['FIRESTORE_EMULATOR_HOST'] = `${FIRESTORE_AT.host}:${String(FIRESTORE_AT.port)}`;
  const app =
    getApps().find((candidate) => candidate.name === 'assistant-provenance') ??
    initializeApp({ projectId: 'nestprep-643b7' }, 'assistant-provenance');
  return getFirestore(app);
}

async function givenTheHousehold(): Promise<void> {
  await givenData(async (db: Firestore) => {
    await setDoc(doc(db, `households/${HOUSEHOLD}`), {
      name: 'Provenance',
      timeZone: 'Africa/Johannesburg',
      members: { [SAM]: 'parent', [PAT]: 'parent' },
      profiles: { [SAM]: SAM_MEMBER, [PAT]: PAT_MEMBER },
    });
    for (const [id, name, uid] of [
      [SAM_MEMBER, 'Sam', SAM],
      [PAT_MEMBER, 'Pat', PAT],
    ] as const) {
      await setDoc(doc(db, `households/${HOUSEHOLD}/members/${id}`), {
        displayName: name,
        color: 'violet',
        role: 'parent',
        claimedBy: uid,
      });
    }
    await setDoc(doc(db, 'appConfig/flags'), { assistants: true });
  });
}

async function anAssistantEvent(recurring = false): Promise<string> {
  const created = await createEvent.run(
    server(),
    sam,
    createEvent.input.parse({
      title: 'Swimming',
      date: '2026-10-31',
      start_time: '09:00',
      end_time: '10:00',
      member_ids: [SAM_MEMBER],
      ...(recurring ? { recurrence: weeklyOn([6]) } : {}),
    }),
    NOW,
  );
  return created.event.id;
}

async function anAssistantItem(): Promise<string> {
  const added = await addGroceryItems.run(
    server(),
    sam,
    addGroceryItems.input.parse({ items: [{ name: 'Milk', quantity: '2 L' }] }),
    NOW,
  );
  return added.added[0]?.id ?? '';
}

beforeEach(async () => {
  await clearData();
  await givenTheHousehold();
});

describe('an event an assistant created', () => {
  it("is edited by its creator's app the way the app edits — `update` of the editable keys", async () => {
    const id = await anAssistantEvent();
    await assertSucceeds(
      updateDoc(doc(await asUser(SAM), `${EVENTS}/${id}`), {
        title: 'Swimming gala',
        note: null,
        date: '2026-10-31',
        startMinute: 600,
        endMinute: 660,
        recurrence: null,
        memberIds: [SAM_MEMBER, PAT_MEMBER],
      }),
    );
  });

  it('is deleted by its creator in the app; a parent who is not the creator is denied', async () => {
    const id = await anAssistantEvent();
    await assertFails(deleteDoc(doc(await asUser(PAT), `${EVENTS}/${id}`)));
    await assertSucceeds(deleteDoc(doc(await asUser(SAM), `${EVENTS}/${id}`)));
  });

  it('keeps its createdVia: a client may not change it or drop it', async () => {
    const id = await anAssistantEvent();
    const db = await asUser(SAM);
    await assertFails(updateDoc(doc(db, `${EVENTS}/${id}`), { createdVia: 'chatgpt' }));
    await assertFails(updateDoc(doc(db, `${EVENTS}/${id}`), { createdVia: deleteField() }));
    await assertFails(
      updateDoc(doc(db, `${EVENTS}/${id}`), { title: 'Swim', createdVia: 'assistant' }),
    );
  });

  it("an occurrence the assistant skipped is unskipped in the app, and re-skipped in the app's shape", async () => {
    const id = await anAssistantEvent(true);
    await deleteEvent.run(
      server(),
      sam,
      { event_id: id, scope: 'occurrence', occurrence_date: '2026-11-07' },
      NOW,
    );
    const db = await asUser(PAT);
    await assertSucceeds(deleteDoc(doc(db, `${SKIPS}/${id}_2026-11-07`)));
    await assertSucceeds(
      setDoc(doc(db, `${SKIPS}/${id}_2026-11-07`), {
        eventId: id,
        occurrenceDate: '2026-11-07',
        skippedBy: PAT_MEMBER,
        skippedAt: serverTimestamp(),
      }),
    );
  });
});

describe('a client cannot claim an assistant made something', () => {
  it('an event created with createdVia is denied; the same event without it is allowed', async () => {
    const db = await asUser(SAM);
    const event = {
      title: 'Dentist',
      note: null,
      date: '2026-11-02',
      startMinute: 600,
      endMinute: 660,
      recurrence: weeklyOn([1]),
      memberIds: [],
      createdBy: SAM_MEMBER,
      createdAt: serverTimestamp(),
    };
    await assertFails(setDoc(doc(db, `${EVENTS}/forged`), { ...event, createdVia: 'claude' }));
    await assertSucceeds(setDoc(doc(db, `${EVENTS}/honest`), event));
  });

  it('an app-made event cannot be given a createdVia later', async () => {
    const db = await asUser(SAM);
    await assertSucceeds(
      setDoc(doc(db, `${EVENTS}/honest`), {
        title: 'Dentist',
        note: null,
        date: '2026-11-02',
        startMinute: null,
        endMinute: null,
        recurrence: null,
        memberIds: [],
        createdBy: SAM_MEMBER,
        createdAt: serverTimestamp(),
      }),
    );
    await assertFails(updateDoc(doc(db, `${EVENTS}/honest`), { createdVia: 'claude' }));
  });

  it('a grocery item created with addedVia is denied; the same item without it is allowed', async () => {
    const db = await asUser(SAM);
    const item = {
      name: 'Bread',
      quantity: null,
      addedBy: SAM_MEMBER,
      addedAt: serverTimestamp(),
      boughtAt: null,
      boughtBy: null,
      sourceKey: null,
      sourceWeek: null,
      sourceNote: null,
    };
    await assertFails(setDoc(doc(db, `${ITEMS}/forged`), { ...item, addedVia: 'chatgpt' }));
    await assertSucceeds(setDoc(doc(db, `${ITEMS}/honest`), item));
    await assertFails(updateDoc(doc(db, `${ITEMS}/honest`), { addedVia: 'claude' }));
  });
});

describe('a grocery item an assistant added', () => {
  it('is ticked by anybody in the app, and unticked', async () => {
    const id = await anAssistantItem();
    const db = await asUser(PAT);
    await assertSucceeds(
      updateDoc(doc(db, `${ITEMS}/${id}`), { boughtAt: serverTimestamp(), boughtBy: PAT_MEMBER }),
    );
    await assertSucceeds(updateDoc(doc(db, `${ITEMS}/${id}`), { boughtAt: null, boughtBy: null }));
  });

  it("is renamed by its adder with the app's own rename write", async () => {
    const id = await anAssistantItem();
    await assertSucceeds(
      updateDoc(doc(await asUser(SAM), `${ITEMS}/${id}`), {
        name: 'Oat milk',
        quantity: '1 L',
        sourceKey: null,
        sourceWeek: null,
        sourceNote: null,
        productMatch: deleteField(),
      }),
    );
  });

  it('is deleted by its adder; a parent who did not add it is denied', async () => {
    const id = await anAssistantItem();
    await assertFails(deleteDoc(doc(await asUser(PAT), `${ITEMS}/${id}`)));
    await assertSucceeds(deleteDoc(doc(await asUser(SAM), `${ITEMS}/${id}`)));
  });

  it('keeps its addedVia: a client may not change it or drop it', async () => {
    const id = await anAssistantItem();
    const db = await asUser(SAM);
    await assertFails(updateDoc(doc(db, `${ITEMS}/${id}`), { addedVia: 'chatgpt' }));
    await assertFails(updateDoc(doc(db, `${ITEMS}/${id}`), { addedVia: deleteField() }));
  });

  it('one the assistant ticked is unticked in the app', async () => {
    const id = await anAssistantItem();
    await tickGroceryItems.run(server(), sam, { item_ids: [id], bought: true }, NOW);
    await assertSucceeds(
      updateDoc(doc(await asUser(PAT), `${ITEMS}/${id}`), { boughtAt: null, boughtBy: null }),
    );
  });
});
