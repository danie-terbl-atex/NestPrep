import {
  deleteDoc,
  doc,
  getDoc,
  getDocs,
  collection,
  serverTimestamp,
  setDoc,
  updateDoc,
  GeoPoint,
  Timestamp,
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
 * `memberLocations` — live-location ADR-0001 and ADR-0002.
 *
 * The denied cases are the feature. Everything else in this app is about a
 * thing; this is about where a person's body is, and the two refusals below
 * are the ones a household is trusting:
 *
 * - **an admin cannot force a share on** somebody who did not start one, and
 * - **one member cannot write another's position**, whatever they put in it.
 *
 * Both are the same rule — `isOwnMember` on the *document id* — which is why
 * the id is the member id and not a field. The third is a consequence of it:
 * a profile nobody has claimed has no `claimedBy`, so no caller in the world
 * can create its document.
 */

const SAM = 'uid-sam';
const THANDI = 'uid-thandi';
const STRANGER = 'uid-stranger';
const HOUSEHOLD = 'h1';
const SAM_MEMBER = 'm-sam';
const THANDI_MEMBER = 'm-thandi';
const KID_MEMBER = 'm-kid';
const LOCATIONS = `households/${HOUSEHOLD}/memberLocations`;

/** Sam is an admin and has signed in; Thandi is a helper and has; the kid has not. */
async function givenTheParkers(): Promise<void> {
  await givenData(async (db: Firestore) => {
    await setDoc(doc(db, `households/${HOUSEHOLD}`), {
      name: 'The Parkers',
      timeZone: 'Africa/Johannesburg',
      members: { [SAM]: 'admin', [THANDI]: 'helper' },
    });
    for (const [id, name, role, claimedBy] of [
      [SAM_MEMBER, 'Sam', 'admin', SAM],
      [THANDI_MEMBER, 'Thandi', 'helper', THANDI],
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

/** Thandi is sharing for the next hour. */
async function givenThandiIsSharing(): Promise<void> {
  await givenData(async (db: Firestore) => {
    await setDoc(doc(db, `${LOCATIONS}/${THANDI_MEMBER}`), {
      point: new GeoPoint(-26.2041, 28.0473),
      accuracyMetres: 12,
      reportedAt: new Date(),
      sharingUntil: Timestamp.fromMillis(Date.now() + 60 * 60 * 1000),
    });
  });
}

function aPositionUntil(millisFromNow: number): Record<string, unknown> {
  return {
    point: new GeoPoint(-26.2041, 28.0473),
    accuracyMetres: 12,
    reportedAt: serverTimestamp(),
    sharingUntil: Timestamp.fromMillis(Date.now() + millisFromNow),
  };
}

const anHour = 60 * 60 * 1000;

describe('memberLocations/{memberId}', () => {
  beforeEach(async () => {
    await clearData();
    await givenTheParkers();
  });

  describe('who may look', () => {
    it('lets any member of the household see who is sharing', async () => {
      await givenThandiIsSharing();
      await assertSucceeds(getDoc(doc(await asUser(SAM), `${LOCATIONS}/${THANDI_MEMBER}`)));
      await assertSucceeds(getDocs(collection(await asUser(THANDI), LOCATIONS)));
    });

    it('denies a stranger reading a single position', async () => {
      await givenThandiIsSharing();
      await assertFails(getDoc(doc(await asUser(STRANGER), `${LOCATIONS}/${THANDI_MEMBER}`)));
    });

    it('denies a stranger listing the collection', async () => {
      await givenThandiIsSharing();
      await assertFails(getDocs(collection(await asUser(STRANGER), LOCATIONS)));
    });

    it('denies somebody who is not signed in at all', async () => {
      await givenThandiIsSharing();
      await assertFails(getDoc(doc(await asSignedOut(), `${LOCATIONS}/${THANDI_MEMBER}`)));
    });
  });

  describe('who may say where they are', () => {
    it('lets a member start their own share', async () => {
      const db = await asUser(THANDI);
      await assertSucceeds(
        setDoc(doc(db, `${LOCATIONS}/${THANDI_MEMBER}`), aPositionUntil(anHour)),
      );
    });

    it('lets that member keep reporting inside the window', async () => {
      await givenThandiIsSharing();
      const db = await asUser(THANDI);
      await assertSucceeds(
        setDoc(doc(db, `${LOCATIONS}/${THANDI_MEMBER}`), aPositionUntil(anHour)),
      );
    });

    it('denies one member writing another"s position', async () => {
      // The document id is the member id, so there is no field to get wrong.
      const db = await asUser(THANDI);
      await assertFails(setDoc(doc(db, `${LOCATIONS}/${SAM_MEMBER}`), aPositionUntil(anHour)));
    });

    it('DENIES AN ADMIN FORCING A SHARE ON somebody else', async () => {
      // The one thing this feature must not permit. An admin may do anything
      // else in this household (household ADR-0001) and cannot do this.
      const db = await asUser(SAM);
      await assertFails(setDoc(doc(db, `${LOCATIONS}/${THANDI_MEMBER}`), aPositionUntil(anHour)));
    });

    it('denies an admin extending somebody else"s open window', async () => {
      await givenThandiIsSharing();
      const db = await asUser(SAM);
      await assertFails(
        updateDoc(doc(db, `${LOCATIONS}/${THANDI_MEMBER}`), {
          sharingUntil: Timestamp.fromMillis(Date.now() + 4 * anHour),
        }),
      );
    });

    it('denies a position for a profile nobody has claimed', async () => {
      // A profile nobody has signed in as has no device. `claimedBy` is null
      // and no uid is null, so there is no caller this can succeed for.
      for (const uid of [SAM, THANDI, STRANGER]) {
        const db = await asUser(uid);
        await assertFails(setDoc(doc(db, `${LOCATIONS}/${KID_MEMBER}`), aPositionUntil(anHour)));
      }
    });

    it('denies a position for a member id that does not exist', async () => {
      const db = await asUser(SAM);
      await assertFails(setDoc(doc(db, `${LOCATIONS}/m-nobody`), aPositionUntil(anHour)));
    });

    it('denies a stranger writing anything at all', async () => {
      const db = await asUser(STRANGER);
      await assertFails(setDoc(doc(db, `${LOCATIONS}/${SAM_MEMBER}`), aPositionUntil(anHour)));
      await assertFails(setDoc(doc(db, `${LOCATIONS}/${THANDI_MEMBER}`), aPositionUntil(anHour)));
    });
  });

  describe('the window', () => {
    it('denies a share longer than four hours', async () => {
      const db = await asUser(THANDI);
      await assertFails(
        setDoc(doc(db, `${LOCATIONS}/${THANDI_MEMBER}`), aPositionUntil(5 * anHour)),
      );
    });

    it('allows one right up to four hours', async () => {
      const db = await asUser(THANDI);
      await assertSucceeds(
        setDoc(doc(db, `${LOCATIONS}/${THANDI_MEMBER}`), aPositionUntil(4 * anHour - 60 * 1000)),
      );
    });

    it('denies a position written after the window has closed', async () => {
      // This is what actually ends a share: the device stops being able to say
      // anything (live-location ADR-0001).
      const db = await asUser(THANDI);
      await assertFails(setDoc(doc(db, `${LOCATIONS}/${THANDI_MEMBER}`), aPositionUntil(-1000)));
    });

    it('denies a window that is not a time at all', async () => {
      const db = await asUser(THANDI);
      await assertFails(
        setDoc(doc(db, `${LOCATIONS}/${THANDI_MEMBER}`), {
          ...aPositionUntil(anHour),
          sharingUntil: 'later',
        }),
      );
    });

    it('denies a position with no window on it', async () => {
      const db = await asUser(THANDI);
      const withoutAWindow = aPositionUntil(anHour);
      delete withoutAWindow.sharingUntil;
      await assertFails(setDoc(doc(db, `${LOCATIONS}/${THANDI_MEMBER}`), withoutAWindow));
    });
  });

  describe('what a position may contain', () => {
    it('denies a position that dates its own arrival', async () => {
      // `reportedAt` is the server's, so "how old is this" is a server fact
      // and not something a device can flatter itself about (`BE-03`).
      const db = await asUser(THANDI);
      await assertFails(
        setDoc(doc(db, `${LOCATIONS}/${THANDI_MEMBER}`), {
          ...aPositionUntil(anHour),
          reportedAt: new Date('2000-01-01'),
        }),
      );
    });

    it('denies a point that is not a point', async () => {
      const db = await asUser(THANDI);
      await assertFails(
        setDoc(doc(db, `${LOCATIONS}/${THANDI_MEMBER}`), {
          ...aPositionUntil(anHour),
          point: { latitude: -26.2041, longitude: 28.0473 },
        }),
      );
    });

    it('denies a negative or non-numeric accuracy', async () => {
      const db = await asUser(THANDI);
      await assertFails(
        setDoc(doc(db, `${LOCATIONS}/${THANDI_MEMBER}`), {
          ...aPositionUntil(anHour),
          accuracyMetres: -1,
        }),
      );
      await assertFails(
        setDoc(doc(db, `${LOCATIONS}/${THANDI_MEMBER}`), {
          ...aPositionUntil(anHour),
          accuracyMetres: 'about twelve',
        }),
      );
    });

    it('denies any field the rule does not name', async () => {
      // A trail, a name, a battery level: anything extra is a thing nobody
      // decided to store about a person.
      const db = await asUser(THANDI);
      await assertFails(
        setDoc(doc(db, `${LOCATIONS}/${THANDI_MEMBER}`), {
          ...aPositionUntil(anHour),
          previousPoints: [new GeoPoint(-26.1, 28.1)],
        }),
      );
    });
  });

  describe('stopping', () => {
    it('lets a member delete their own position', async () => {
      await givenThandiIsSharing();
      await assertSucceeds(deleteDoc(doc(await asUser(THANDI), `${LOCATIONS}/${THANDI_MEMBER}`)));
    });

    it('lets an admin clear a pin a dead phone left behind', async () => {
      // A delete only ever removes what somebody can see; it never reveals
      // anything, so it is the one thing an admin may do here.
      await givenThandiIsSharing();
      await assertSucceeds(deleteDoc(doc(await asUser(SAM), `${LOCATIONS}/${THANDI_MEMBER}`)));
    });

    it('denies a non-admin deleting somebody else"s position', async () => {
      await givenData(async (db: Firestore) => {
        await setDoc(doc(db, `${LOCATIONS}/${SAM_MEMBER}`), {
          point: new GeoPoint(-26.2041, 28.0473),
          accuracyMetres: 12,
          reportedAt: new Date(),
          sharingUntil: Timestamp.fromMillis(Date.now() + anHour),
        });
      });
      await assertFails(deleteDoc(doc(await asUser(THANDI), `${LOCATIONS}/${SAM_MEMBER}`)));
    });

    it('denies a stranger deleting anything', async () => {
      await givenThandiIsSharing();
      await assertFails(deleteDoc(doc(await asUser(STRANGER), `${LOCATIONS}/${THANDI_MEMBER}`)));
    });
  });
});
