import {
  collection,
  deleteDoc,
  doc,
  getDoc,
  getDocs,
  GeoPoint,
  serverTimestamp,
  setDoc,
  Timestamp,
  updateDoc,
} from 'firebase/firestore';
import { beforeEach, describe, it } from 'vitest';

import {
  asSignedOut,
  asUser,
  assertFails,
  assertSucceeds,
  clearData,
  givenData,
  type Firestore,
} from './rules_harness';

/**
 * `memberLocations` — live-location ADR-0001, ADR-0003 and ADR-0004.
 *
 * Two refusals are the ones a household is trusting: an admin cannot force a
 * share on, and one member cannot write another's position. Both are
 * `isOwnMember` on the document id.
 */

const SAM = 'uid-sam';
const THANDI = 'uid-thandi';
const NOMSA = 'uid-nomsa';
const STRANGER = 'uid-stranger';
const HOUSEHOLD = 'h1';
const SAM_MEMBER = 'm-sam';
const THANDI_MEMBER = 'm-thandi';
const NOMSA_MEMBER = 'm-nomsa';
const KID_MEMBER = 'm-kid';
const LOCATIONS = `households/${HOUSEHOLD}/memberLocations`;
const ENTITLEMENT = `households/${HOUSEHOLD}/entitlement/current`;

const anHour = 60 * 60 * 1000;

/**
 * Sam is an admin. Thandi is a helper claimed before grants existed, so she
 * holds `edit` everywhere. Nomsa is a helper whose parent chose her grant,
 * which says nothing about location. The kid has not signed in.
 */
async function givenTheParkers(): Promise<void> {
  await givenData(async (db: Firestore) => {
    await setDoc(doc(db, `households/${HOUSEHOLD}`), {
      name: 'The Parkers',
      timeZone: 'Africa/Johannesburg',
      members: { [SAM]: 'admin', [THANDI]: 'helper', [NOMSA]: 'helper' },
      access: { [NOMSA]: { calendar: 'view', groceries: 'edit' } },
    });
    for (const [id, name, role, claimedBy] of [
      [SAM_MEMBER, 'Sam', 'admin', SAM],
      [THANDI_MEMBER, 'Thandi', 'helper', THANDI],
      [NOMSA_MEMBER, 'Nomsa', 'helper', NOMSA],
      [KID_MEMBER, 'Kid', 'member', null],
    ] as const) {
      await setDoc(doc(db, `households/${HOUSEHOLD}/members/${id}`), {
        displayName: name,
        color: 'violet',
        role,
        claimedBy,
      });
    }
  });
}

async function givenPremium(millisFromNow: number): Promise<void> {
  await givenData(async (db: Firestore) => {
    await setDoc(doc(db, ENTITLEMENT), {
      premiumUntil: Timestamp.fromMillis(Date.now() + millisFromNow),
    });
  });
}

async function givenSharing(memberId: string, fields: Record<string, unknown> = {}): Promise<void> {
  await givenData(async (db: Firestore) => {
    await setDoc(doc(db, `${LOCATIONS}/${memberId}`), {
      point: new GeoPoint(-26.2041, 28.0473),
      accuracyMetres: 12,
      reportedAt: Timestamp.fromMillis(Date.now() - 60 * 1000),
      sharingUntil: Timestamp.fromMillis(Date.now() + anHour),
      ...fields,
    });
  });
}

function aPositionUntil(
  millisFromNow: number,
  fields: Record<string, unknown> = {},
): Record<string, unknown> {
  return {
    point: new GeoPoint(-26.2041, 28.0473),
    accuracyMetres: 12,
    reportedAt: serverTimestamp(),
    sharingUntil: Timestamp.fromMillis(Date.now() + millisFromNow),
    ...fields,
  };
}

function continuous(fields: Record<string, unknown> = {}): Record<string, unknown> {
  return aPositionUntil(24 * anHour, { mode: 'continuous', ...fields });
}

describe('memberLocations/{memberId}', () => {
  beforeEach(async () => {
    await clearData();
    await givenTheParkers();
  });

  describe('who may look', () => {
    it('lets family and a helper holding the grant see who is sharing', async () => {
      await givenSharing(THANDI_MEMBER);
      await assertSucceeds(getDoc(doc(await asUser(SAM), `${LOCATIONS}/${THANDI_MEMBER}`)));
      await assertSucceeds(getDocs(collection(await asUser(THANDI), LOCATIONS)));
    });

    it('denies a helper whose grant does not open location', async () => {
      await givenSharing(SAM_MEMBER);
      await assertFails(getDocs(collection(await asUser(NOMSA), LOCATIONS)));
      await assertFails(getDoc(doc(await asUser(NOMSA), `${LOCATIONS}/${SAM_MEMBER}`)));
    });

    it('lets that helper look once a parent grants it', async () => {
      await givenSharing(SAM_MEMBER);
      await givenData(async (db: Firestore) => {
        await updateDoc(doc(db, `households/${HOUSEHOLD}`), {
          [`access.${NOMSA}`]: { location: 'view' },
        });
      });
      await assertSucceeds(getDocs(collection(await asUser(NOMSA), LOCATIONS)));
    });

    it('denies a stranger and somebody signed out', async () => {
      await givenSharing(THANDI_MEMBER);
      await assertFails(getDoc(doc(await asUser(STRANGER), `${LOCATIONS}/${THANDI_MEMBER}`)));
      await assertFails(getDocs(collection(await asUser(STRANGER), LOCATIONS)));
      await assertFails(getDoc(doc(await asSignedOut(), `${LOCATIONS}/${THANDI_MEMBER}`)));
    });
  });

  describe('who may say where they are', () => {
    it('lets a member start their own share, grant or no grant', async () => {
      await assertSucceeds(
        setDoc(doc(await asUser(NOMSA), `${LOCATIONS}/${NOMSA_MEMBER}`), aPositionUntil(anHour)),
      );
    });

    it('denies one member writing another"s position', async () => {
      const db = await asUser(THANDI);
      await assertFails(setDoc(doc(db, `${LOCATIONS}/${SAM_MEMBER}`), aPositionUntil(anHour)));
    });

    it('DENIES AN ADMIN FORCING A SHARE ON somebody else', async () => {
      await givenPremium(anHour);
      const db = await asUser(SAM);
      await assertFails(setDoc(doc(db, `${LOCATIONS}/${THANDI_MEMBER}`), aPositionUntil(anHour)));
      await assertFails(setDoc(doc(db, `${LOCATIONS}/${THANDI_MEMBER}`), continuous()));
    });

    it('denies an admin extending somebody else"s open window', async () => {
      await givenSharing(THANDI_MEMBER);
      await assertFails(
        updateDoc(doc(await asUser(SAM), `${LOCATIONS}/${THANDI_MEMBER}`), {
          sharingUntil: Timestamp.fromMillis(Date.now() + 4 * anHour),
        }),
      );
    });

    it('denies a position for a profile nobody has claimed or no profile at all', async () => {
      for (const uid of [SAM, THANDI, STRANGER]) {
        const db = await asUser(uid);
        await assertFails(setDoc(doc(db, `${LOCATIONS}/${KID_MEMBER}`), aPositionUntil(anHour)));
      }
      await assertFails(
        setDoc(doc(await asUser(SAM), `${LOCATIONS}/m-nobody`), aPositionUntil(anHour)),
      );
    });
  });

  describe('a window share', () => {
    it('allows one right up to four hours and denies one longer', async () => {
      const db = await asUser(THANDI);
      await assertSucceeds(
        setDoc(doc(db, `${LOCATIONS}/${THANDI_MEMBER}`), aPositionUntil(4 * anHour - 60_000)),
      );
      await clearData();
      await givenTheParkers();
      await assertFails(
        setDoc(doc(db, `${LOCATIONS}/${THANDI_MEMBER}`), aPositionUntil(5 * anHour)),
      );
    });

    it('denies a position after the window has closed, or with no window', async () => {
      const db = await asUser(THANDI);
      await assertFails(setDoc(doc(db, `${LOCATIONS}/${THANDI_MEMBER}`), aPositionUntil(-1000)));
      await assertFails(
        setDoc(
          doc(db, `${LOCATIONS}/${THANDI_MEMBER}`),
          aPositionUntil(anHour, { sharingUntil: 'later' }),
        ),
      );
      const withoutAWindow = aPositionUntil(anHour);
      delete withoutAWindow['sharingUntil'];
      await assertFails(setDoc(doc(db, `${LOCATIONS}/${THANDI_MEMBER}`), withoutAWindow));
    });

    it('is free', async () => {
      await assertSucceeds(
        setDoc(
          doc(await asUser(THANDI), `${LOCATIONS}/${THANDI_MEMBER}`),
          aPositionUntil(anHour, { mode: 'window' }),
        ),
      );
    });
  });

  describe('continuous sharing', () => {
    it('lets a premium household keep a 24-hour lease', async () => {
      await givenPremium(anHour);
      await assertSucceeds(
        setDoc(doc(await asUser(THANDI), `${LOCATIONS}/${THANDI_MEMBER}`), continuous()),
      );
    });

    it('denies it to a free or lapsed household', async () => {
      const db = await asUser(THANDI);
      await assertFails(setDoc(doc(db, `${LOCATIONS}/${THANDI_MEMBER}`), continuous()));
      await givenPremium(-1000);
      await assertFails(setDoc(doc(db, `${LOCATIONS}/${THANDI_MEMBER}`), continuous()));
    });

    it('denies a lease longer than a day', async () => {
      await givenPremium(anHour);
      await assertFails(
        setDoc(
          doc(await asUser(THANDI), `${LOCATIONS}/${THANDI_MEMBER}`),
          continuous({ sharingUntil: Timestamp.fromMillis(Date.now() + 26 * anHour) }),
        ),
      );
    });

    it('denies a mode nobody decided on', async () => {
      await givenPremium(anHour);
      await assertFails(
        setDoc(
          doc(await asUser(THANDI), `${LOCATIONS}/${THANDI_MEMBER}`),
          continuous({ mode: 'forever' }),
        ),
      );
    });
  });

  describe('pace', () => {
    it('denies a second write inside ten seconds', async () => {
      await givenSharing(THANDI_MEMBER, { reportedAt: Timestamp.fromMillis(Date.now() - 2000) });
      await assertFails(
        setDoc(doc(await asUser(THANDI), `${LOCATIONS}/${THANDI_MEMBER}`), aPositionUntil(anHour)),
      );
    });

    it('allows one after ten seconds', async () => {
      await givenSharing(THANDI_MEMBER, { reportedAt: Timestamp.fromMillis(Date.now() - 11_000) });
      await assertSucceeds(
        setDoc(doc(await asUser(THANDI), `${LOCATIONS}/${THANDI_MEMBER}`), aPositionUntil(anHour)),
      );
    });

    it('never holds switching from a window to continuous', async () => {
      await givenPremium(anHour);
      await givenSharing(THANDI_MEMBER, { reportedAt: Timestamp.fromMillis(Date.now() - 2000) });
      await assertSucceeds(
        setDoc(doc(await asUser(THANDI), `${LOCATIONS}/${THANDI_MEMBER}`), continuous()),
      );
    });
  });

  describe('what a position may contain', () => {
    it('accepts the battery and how the member is moving', async () => {
      await assertSucceeds(
        setDoc(
          doc(await asUser(THANDI), `${LOCATIONS}/${THANDI_MEMBER}`),
          aPositionUntil(anHour, { batteryPercent: 64, charging: false, motion: 'driving' }),
        ),
      );
    });

    it('denies a battery outside 0–100, a non-bool charging and an unknown motion', async () => {
      const db = await asUser(THANDI);
      const path = `${LOCATIONS}/${THANDI_MEMBER}`;
      await assertFails(setDoc(doc(db, path), aPositionUntil(anHour, { batteryPercent: 101 })));
      await assertFails(setDoc(doc(db, path), aPositionUntil(anHour, { batteryPercent: 50.5 })));
      await assertFails(setDoc(doc(db, path), aPositionUntil(anHour, { charging: 'yes' })));
      await assertFails(setDoc(doc(db, path), aPositionUntil(anHour, { motion: 'flying' })));
    });

    it('denies a position that dates its own arrival', async () => {
      await assertFails(
        setDoc(
          doc(await asUser(THANDI), `${LOCATIONS}/${THANDI_MEMBER}`),
          aPositionUntil(anHour, { reportedAt: new Date('2000-01-01') }),
        ),
      );
    });

    it('denies a point that is not a point, and a bad accuracy', async () => {
      const db = await asUser(THANDI);
      const path = `${LOCATIONS}/${THANDI_MEMBER}`;
      await assertFails(
        setDoc(
          doc(db, path),
          aPositionUntil(anHour, { point: { latitude: -26.2041, longitude: 28.0473 } }),
        ),
      );
      await assertFails(setDoc(doc(db, path), aPositionUntil(anHour, { accuracyMetres: -1 })));
      await assertFails(
        setDoc(doc(db, path), aPositionUntil(anHour, { accuracyMetres: 'about twelve' })),
      );
    });

    it('denies any field the rule does not name — a trail lives elsewhere', async () => {
      await assertFails(
        setDoc(
          doc(await asUser(THANDI), `${LOCATIONS}/${THANDI_MEMBER}`),
          aPositionUntil(anHour, { previousPoints: [new GeoPoint(-26.1, 28.1)] }),
        ),
      );
    });
  });

  describe('stopping', () => {
    it('lets a member delete their own position and an admin clear a dead phone"s', async () => {
      await givenSharing(THANDI_MEMBER);
      await assertSucceeds(deleteDoc(doc(await asUser(THANDI), `${LOCATIONS}/${THANDI_MEMBER}`)));
      await givenSharing(THANDI_MEMBER);
      await assertSucceeds(deleteDoc(doc(await asUser(SAM), `${LOCATIONS}/${THANDI_MEMBER}`)));
    });

    it('denies a non-admin or a stranger deleting somebody else"s', async () => {
      await givenSharing(SAM_MEMBER);
      await assertFails(deleteDoc(doc(await asUser(THANDI), `${LOCATIONS}/${SAM_MEMBER}`)));
      await assertFails(deleteDoc(doc(await asUser(STRANGER), `${LOCATIONS}/${SAM_MEMBER}`)));
    });
  });
});
