import { deleteDoc, deleteField, doc, getDoc, setDoc, updateDoc } from 'firebase/firestore';
import { beforeEach, describe, it } from 'vitest';

import {
  HOME,
  HOUSEHOLD,
  KID_DEVICE,
  PEOPLE,
  givenAHouseholdOfEveryRole,
  type Person,
} from './access_fixture';
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

/**
 * Photo frames (photo-frames ADR-0001): family reads, renames, chooses the
 * panels of and deletes a frame; nobody else touches one, and nobody creates
 * one — `claimFramePairing` does. Pairing codes and credentials are closed to
 * every client.
 */

const FRAME = `${HOME}/frames/kitchen`;

const PANELS = { calendar: true, todos: true, meals: false, helperMemberId: null };

function frame(): Record<string, unknown> {
  return {
    name: 'Kitchen',
    panels: PANELS,
    model: 'Frameo 10',
    linkedBy: PEOPLE.admin.member,
    linkedAt: new Date(),
    lastSeenAt: null,
  };
}

const FAMILY: Person[] = ['admin', 'parent', 'legacyMember'];
const NOT_FAMILY: Person[] = ['kid', 'carer', 'cleaner', 'viewer', 'legacyHelper'];

const kidDevice = (): Promise<Firestore> =>
  asKid(KID_DEVICE, { householdId: HOUSEHOLD, memberId: PEOPLE.kid.member });

beforeEach(async () => {
  await clearData();
  await givenAHouseholdOfEveryRole();
  await givenData(async (db) => {
    await setDoc(doc(db, FRAME), frame());
    await setDoc(doc(db, 'framePairings/ABC234'), {
      secretHash: 'h',
      status: 'waiting',
      expiresAt: new Date(),
    });
    await setDoc(doc(db, 'frameCredentials/h'), { householdId: HOUSEHOLD, frameId: 'kitchen' });
  });
});

describe('family looks after the household’s frames', () => {
  for (const person of FAMILY) {
    it(`${person} reads, renames, rechooses and deletes one`, async () => {
      const db = await asUser(PEOPLE[person].uid);
      await assertSucceeds(getDoc(doc(db, FRAME)));
      await assertSucceeds(updateDoc(doc(db, FRAME), { name: 'Hallway' }));
      await assertSucceeds(
        updateDoc(doc(db, FRAME), {
          panels: {
            calendar: false,
            todos: true,
            meals: true,
            helperMemberId: PEOPLE.cleaner.member,
          },
        }),
      );
      await assertSucceeds(deleteDoc(doc(db, FRAME)));
    });
  }

  it('but never creates one: a frame is linked by its code', async () => {
    const db = await asUser(PEOPLE.admin.uid);
    await assertFails(setDoc(doc(db, `${HOME}/frames/new`), frame()));
  });

  it('and changes nothing but the name, the panels and the screensaver', async () => {
    const db = await asUser(PEOPLE.admin.uid);
    await assertFails(updateDoc(doc(db, FRAME), { lastSeenAt: new Date() }));
    await assertFails(updateDoc(doc(db, FRAME), { linkedBy: PEOPLE.parent.member }));
    await assertFails(updateDoc(doc(db, FRAME), { model: 'Other' }));
    await assertFails(updateDoc(doc(db, FRAME), { name: 'Kitchen', extra: true }));
  });

  it('with a name of one to forty characters', async () => {
    const db = await asUser(PEOPLE.admin.uid);
    await assertFails(updateDoc(doc(db, FRAME), { name: '' }));
    await assertFails(updateDoc(doc(db, FRAME), { name: 'x'.repeat(41) }));
    await assertFails(updateDoc(doc(db, FRAME), { name: 7 }));
    await assertSucceeds(updateDoc(doc(db, FRAME), { name: 'x'.repeat(40) }));
  });

  it('and panels of exactly the frame’s shape, naming a helper who exists', async () => {
    const db = await asUser(PEOPLE.admin.uid);
    for (const panels of [
      { calendar: true, todos: true, meals: true },
      { ...PANELS, weather: true },
      { ...PANELS, calendar: 'yes' },
      { ...PANELS, helperMemberId: '' },
      { ...PANELS, helperMemberId: 'm-nobody' },
      { ...PANELS, lunch: 'yes' },
      { ...PANELS, lunch: null },
      { ...PANELS, lunch: true, packing: true },
      { ...PANELS, addEvents: 'yes' },
      { ...PANELS, addEvents: null },
      { ...PANELS, lunch: true, addEvents: 1 },
      { ...PANELS, share: 'yes' },
      { ...PANELS, share: null },
      { ...PANELS, share: 1 },
      { ...PANELS, people: 'yes' },
      { ...PANELS, people: null },
      { ...PANELS, people: 1 },
      'all',
    ]) {
      await assertFails(updateDoc(doc(db, FRAME), { panels }));
    }
  });

  it('with the lunch switch or without it, as an older app writes them', async () => {
    const db = await asUser(PEOPLE.admin.uid);
    await assertSucceeds(updateDoc(doc(db, FRAME), { panels: { ...PANELS, lunch: true } }));
    await assertSucceeds(updateDoc(doc(db, FRAME), { panels: { ...PANELS, lunch: false } }));
    await assertSucceeds(updateDoc(doc(db, FRAME), { panels: PANELS }));
  });

  it('with the switch to add events or without it, as an older app writes them', async () => {
    const db = await asUser(PEOPLE.parent.uid);
    await assertSucceeds(updateDoc(doc(db, FRAME), { panels: { ...PANELS, addEvents: true } }));
    await assertSucceeds(
      updateDoc(doc(db, FRAME), { panels: { ...PANELS, lunch: true, addEvents: false } }),
    );
    await assertSucceeds(updateDoc(doc(db, FRAME), { panels: PANELS }));
  });

  it('with the switch to open shared pages or without it, as an older app writes them', async () => {
    const db = await asUser(PEOPLE.parent.uid);
    await assertSucceeds(updateDoc(doc(db, FRAME), { panels: { ...PANELS, share: true } }));
    await assertSucceeds(
      updateDoc(doc(db, FRAME), {
        panels: { ...PANELS, lunch: true, addEvents: true, share: false },
      }),
    );
    await assertSucceeds(updateDoc(doc(db, FRAME), { panels: PANELS }));
  });

  it('with the switch to show where everyone is or without it, as an older app writes them', async () => {
    const db = await asUser(PEOPLE.parent.uid);
    await assertSucceeds(updateDoc(doc(db, FRAME), { panels: { ...PANELS, people: true } }));
    await assertSucceeds(
      updateDoc(doc(db, FRAME), {
        panels: { ...PANELS, lunch: true, addEvents: true, share: true, people: false },
      }),
    );
    await assertSucceeds(updateDoc(doc(db, FRAME), { panels: PANELS }));
  });

  it('but nobody outside the family switches where everyone is on', async () => {
    for (const person of NOT_FAMILY) {
      const db = await asUser(PEOPLE[person].uid);
      await assertFails(updateDoc(doc(db, FRAME), { panels: { ...PANELS, people: true } }));
    }
    const db = await kidDevice();
    await assertFails(updateDoc(doc(db, FRAME), { panels: { ...PANELS, people: true } }));
  });

  it('but never writes the share itself, which only `shareToFrame` does', async () => {
    const db = await asUser(PEOPLE.admin.uid);
    const shared = {
      id: 'share-0001',
      url: 'http://router.lan/',
      title: null,
      by: 'Sam',
      at: new Date(),
    };
    await assertFails(updateDoc(doc(db, FRAME), { share: shared }));
    await assertFails(updateDoc(doc(db, FRAME), { share: null }));
    await assertFails(
      updateDoc(doc(db, FRAME), { panels: { ...PANELS, share: true }, share: shared }),
    );
  });

  it('nor says what the frame opens, which only the frame does through `waitFrameShare`', async () => {
    const db = await asUser(PEOPLE.admin.uid);
    await assertFails(updateDoc(doc(db, FRAME), { accepts: ['page', 'recipe'] }));
    await assertFails(updateDoc(doc(db, FRAME), { name: 'Hallway', accepts: ['page'] }));
  });

  it('and a shared page stays put while family renames the frame', async () => {
    await givenData(async (admin) => {
      await updateDoc(doc(admin, FRAME), {
        panels: { ...PANELS, share: true },
        share: {
          id: 'share-0001',
          url: 'https://example.com/',
          title: null,
          by: 'Sam',
          at: new Date(),
        },
      });
    });
    const db = await asUser(PEOPLE.parent.uid);
    await assertSucceeds(updateDoc(doc(db, FRAME), { name: 'Hallway' }));
    await assertSucceeds(updateDoc(doc(db, FRAME), { panels: { ...PANELS, share: false } }));
  });

  it('but nobody outside the family switches sharing on', async () => {
    for (const person of NOT_FAMILY) {
      const db = await asUser(PEOPLE[person].uid);
      await assertFails(updateDoc(doc(db, FRAME), { panels: { ...PANELS, share: true } }));
    }
    const db = await kidDevice();
    await assertFails(updateDoc(doc(db, FRAME), { panels: { ...PANELS, share: true } }));
  });

  it('but nobody outside the family switches adding on', async () => {
    for (const person of NOT_FAMILY) {
      const db = await asUser(PEOPLE[person].uid);
      await assertFails(updateDoc(doc(db, FRAME), { panels: { ...PANELS, addEvents: true } }));
    }
  });
});

describe('family chooses a frame’s screensaver', () => {
  it('from the choices, off included, alone or with the name and panels', async () => {
    const db = await asUser(PEOPLE.parent.uid);
    for (const screensaver of [
      { idleMinutes: 5, secondsPerPhoto: 20 },
      { idleMinutes: 60, secondsPerPhoto: 10 },
      { idleMinutes: 0, secondsPerPhoto: 30 },
    ]) {
      await assertSucceeds(updateDoc(doc(db, FRAME), { screensaver }));
    }
    await assertSucceeds(
      updateDoc(doc(db, FRAME), {
        name: 'Hallway',
        panels: { ...PANELS, lunch: true },
        screensaver: { idleMinutes: 1, secondsPerPhoto: 60 },
      }),
    );
    await assertSucceeds(updateDoc(doc(db, FRAME), { screensaver: null }));
  });

  it('and nothing off the list or out of shape', async () => {
    const db = await asUser(PEOPLE.admin.uid);
    for (const screensaver of [
      { idleMinutes: 3, secondsPerPhoto: 20 },
      { idleMinutes: 5, secondsPerPhoto: 15 },
      { idleMinutes: '5', secondsPerPhoto: 20 },
      { idleMinutes: 5 },
      { secondsPerPhoto: 20 },
      { idleMinutes: 5, secondsPerPhoto: 20, shuffle: true },
      'on',
      true,
    ]) {
      await assertFails(updateDoc(doc(db, FRAME), { screensaver }));
    }
  });

  it('which nobody outside the family may', async () => {
    for (const person of NOT_FAMILY) {
      const db = await asUser(PEOPLE[person].uid);
      await assertFails(
        updateDoc(doc(db, FRAME), { screensaver: { idleMinutes: 5, secondsPerPhoto: 20 } }),
      );
    }
    const db = await kidDevice();
    await assertFails(
      updateDoc(doc(db, FRAME), { screensaver: { idleMinutes: 5, secondsPerPhoto: 20 } }),
    );
  });
});

describe('family chooses where a frame adds groceries from', () => {
  it('any connected shop, any of the app’s areas, alone or with the rest', async () => {
    const db = await asUser(PEOPLE.parent.uid);
    for (const groceries of [
      { shop: 'checkers', area: 'capeTown' },
      { shop: 'pickNPay', area: 'eastLondon' },
      { shop: 'checkers', area: 'bloemfontein' },
      { shop: 'woolworths', area: 'capeTown', store: '2008', priceZone: 'p30' },
      { shop: 'woolworths', area: 'durban', store: '1234567890', priceZone: 'p10' },
      { shop: 'woolworths', area: 'pretoria', store: '7', priceZone: 'p60' },
    ]) {
      await assertSucceeds(updateDoc(doc(db, FRAME), { groceries }));
    }
    await assertSucceeds(
      updateDoc(doc(db, FRAME), {
        name: 'Hallway',
        panels: { ...PANELS, lunch: true },
        screensaver: { idleMinutes: 1, secondsPerPhoto: 60 },
        groceries: { shop: 'pickNPay', area: 'durban' },
      }),
    );
    await assertSucceeds(updateDoc(doc(db, FRAME), { groceries: deleteField() }));
    await assertSucceeds(updateDoc(doc(db, FRAME), { groceries: null }));
  });

  it('and nothing off the list or out of shape', async () => {
    const db = await asUser(PEOPLE.admin.uid);
    for (const groceries of [
      { shop: 'spar', area: 'capeTown' },
      { shop: 'checkers', area: 'london' },
      { shop: 'Checkers', area: 'capeTown' },
      { shop: 'checkers' },
      { area: 'capeTown' },
      { shop: 'checkers', area: 'capeTown', cart: true },
      'checkers',
      true,
    ]) {
      await assertFails(updateDoc(doc(db, FRAME), { groceries }));
    }
  });

  it('Woolworths only with the store and price list, and no other shop with them', async () => {
    const db = await asUser(PEOPLE.admin.uid);
    const woolworths = { shop: 'woolworths', area: 'capeTown', store: '2008', priceZone: 'p30' };
    for (const groceries of [
      { shop: 'woolworths', area: 'capeTown' },
      { shop: 'woolworths', area: 'capeTown', store: '2008' },
      { shop: 'woolworths', area: 'capeTown', priceZone: 'p30' },
      { ...woolworths, store: '' },
      { ...woolworths, store: '12345678901' },
      { ...woolworths, store: '20a8' },
      { ...woolworths, store: 2008 },
      { ...woolworths, priceZone: 'p20' },
      { ...woolworths, priceZone: 'plist3620008' },
      { ...woolworths, area: 'london' },
      { ...woolworths, cart: true },
      { shop: 'checkers', area: 'capeTown', store: '2008', priceZone: 'p30' },
      { shop: 'pickNPay', area: 'capeTown', store: '2008' },
      { shop: 'checkers', area: 'capeTown', priceZone: 'p30' },
    ]) {
      await assertFails(updateDoc(doc(db, FRAME), { groceries }));
    }
  });

  it('which nobody outside the family may', async () => {
    for (const person of NOT_FAMILY) {
      const db = await asUser(PEOPLE[person].uid);
      await assertFails(
        updateDoc(doc(db, FRAME), { groceries: { shop: 'checkers', area: 'capeTown' } }),
      );
    }
    const db = await kidDevice();
    await assertFails(
      updateDoc(doc(db, FRAME), { groceries: { shop: 'checkers', area: 'capeTown' } }),
    );
    for (const person of NOT_FAMILY) {
      const other = await asUser(PEOPLE[person].uid);
      await assertFails(
        updateDoc(doc(other, FRAME), {
          groceries: { shop: 'woolworths', area: 'capeTown', store: '2008', priceZone: 'p30' },
        }),
      );
    }
  });
});

describe('nobody else touches a frame', () => {
  for (const person of NOT_FAMILY) {
    it(`not ${person}, whatever their grant`, async () => {
      const db = await asUser(PEOPLE[person].uid);
      await assertFails(getDoc(doc(db, FRAME)));
      await assertFails(updateDoc(doc(db, FRAME), { name: 'Mine' }));
      await assertFails(deleteDoc(doc(db, FRAME)));
      await assertFails(setDoc(doc(db, `${HOME}/frames/new`), frame()));
    });
  }

  it('not a kid device', async () => {
    const db = await kidDevice();
    await assertFails(getDoc(doc(db, FRAME)));
    await assertFails(updateDoc(doc(db, FRAME), { name: 'Mine' }));
    await assertFails(deleteDoc(doc(db, FRAME)));
  });

  it('not somebody from another household', async () => {
    const db = await asUser('uid-stranger');
    await assertFails(getDoc(doc(db, FRAME)));
    await assertFails(updateDoc(doc(db, FRAME), { name: 'Mine' }));
    await assertFails(deleteDoc(doc(db, FRAME)));
  });

  it('not anybody signed out', async () => {
    const db = await asSignedOut();
    await assertFails(getDoc(doc(db, FRAME)));
    await assertFails(deleteDoc(doc(db, FRAME)));
  });
});

describe('pairing codes and credentials are closed to every client', () => {
  for (const [label, open] of [
    ['family', (): Promise<Firestore> => asUser(PEOPLE.admin.uid)],
    ['a helper', (): Promise<Firestore> => asUser(PEOPLE.cleaner.uid)],
    ['a kid device', kidDevice],
    ['anybody signed out', asSignedOut],
  ] as const) {
    it(label, async () => {
      const db = await open();
      await assertFails(getDoc(doc(db, 'framePairings/ABC234')));
      await assertFails(setDoc(doc(db, 'framePairings/XYZ789'), { secretHash: 'x' }));
      await assertFails(updateDoc(doc(db, 'framePairings/ABC234'), { status: 'linked' }));
      await assertFails(getDoc(doc(db, 'frameCredentials/h')));
      await assertFails(setDoc(doc(db, 'frameCredentials/x'), { householdId: HOUSEHOLD }));
      await assertFails(deleteDoc(doc(db, 'frameCredentials/h')));
    });
  }
});
