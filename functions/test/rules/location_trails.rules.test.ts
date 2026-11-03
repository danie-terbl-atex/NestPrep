import {
  arrayUnion,
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
  asUser,
  assertFails,
  assertSucceeds,
  clearData,
  givenData,
  type Firestore,
} from './rules_harness';

/** `locationTrails` and `places` — live-location ADR-0004 and ADR-0006. */

const SAM = 'uid-sam';
const LERATO = 'uid-lerato';
const NOMSA = 'uid-nomsa';
const STRANGER = 'uid-stranger';
const HOUSEHOLD = 'h1';
const HOME = `households/${HOUSEHOLD}`;
const SAM_MEMBER = 'm-sam';
const LERATO_MEMBER = 'm-lerato';
const NOMSA_MEMBER = 'm-nomsa';
const DAY = '2026-11-02';
const SAMS_DAY = `${HOME}/locationTrails/${SAM_MEMBER}/trailDays/${DAY}`;
const SAMS_EVENTS = `${HOME}/locationTrails/${SAM_MEMBER}/placeEvents`;
const PLACES = `${HOME}/places`;

const aDay = 24 * 60 * 60 * 1000;

/** Sam is an admin, Lerato a parent, Nomsa a helper whose grant is location `none`. */
async function givenTheParkers(premium: boolean): Promise<void> {
  await givenData(async (db: Firestore) => {
    await setDoc(doc(db, HOME), {
      name: 'The Parkers',
      timeZone: 'Africa/Johannesburg',
      members: { [SAM]: 'admin', [LERATO]: 'parent', [NOMSA]: 'helper' },
      access: { [NOMSA]: { calendar: 'view', location: 'none' } },
    });
    for (const [id, role, claimedBy] of [
      [SAM_MEMBER, 'admin', SAM],
      [LERATO_MEMBER, 'parent', LERATO],
      [NOMSA_MEMBER, 'helper', NOMSA],
    ] as const) {
      await setDoc(doc(db, `${HOME}/members/${id}`), {
        displayName: id,
        color: 'violet',
        role,
        claimedBy,
      });
    }
    if (premium) {
      await setDoc(doc(db, `${HOME}/entitlement/current`), {
        premiumUntil: Timestamp.fromMillis(Date.now() + aDay),
      });
    }
    await setDoc(doc(db, `${PLACES}/school`), aPlace());
  });
}

function points(count: number, from = 0): Record<string, number>[] {
  return Array.from({ length: count }, (_, i) => ({
    t: 1_793_000_000 + (from + i) * 60,
    la: -26.2 + i / 10_000,
    lo: 28.04,
    ac: 12,
  }));
}

function aDayOf(pointList: Record<string, number>[]): Record<string, unknown> {
  return {
    points: pointList,
    updatedAt: serverTimestamp(),
    expiresAt: Timestamp.fromMillis(Date.now() + 30 * aDay),
  };
}

async function givenSamsDay(count: number, updatedMillisAgo: number): Promise<void> {
  await givenData(async (db: Firestore) => {
    await setDoc(doc(db, SAMS_DAY), {
      points: points(count),
      updatedAt: Timestamp.fromMillis(Date.now() - updatedMillisAgo),
      expiresAt: Timestamp.fromMillis(Date.now() + 30 * aDay),
    });
  });
}

function anEvent(fields: Record<string, unknown> = {}): Record<string, unknown> {
  return {
    placeId: 'school',
    kind: 'arrive',
    at: serverTimestamp(),
    expiresAt: Timestamp.fromMillis(Date.now() + 30 * aDay),
    ...fields,
  };
}

function aPlace(fields: Record<string, unknown> = {}): Record<string, unknown> {
  return {
    name: 'School',
    centre: new GeoPoint(-26.1, 28.05),
    radiusMetres: 150,
    icon: 'school',
    alerts: { arrive: true, leave: false },
    updatedAt: serverTimestamp(),
    ...fields,
  };
}

describe('locationTrails/{memberId}/trailDays/{day}', () => {
  beforeEach(async () => {
    await clearData();
    await givenTheParkers(true);
  });

  it('lets a member start their own day and family read it', async () => {
    await assertSucceeds(setDoc(doc(await asUser(SAM), SAMS_DAY), aDayOf(points(30))));
    await assertSucceeds(getDoc(doc(await asUser(LERATO), SAMS_DAY)));
  });

  it('denies a helper without the grant reading it', async () => {
    await givenSamsDay(10, 60_000);
    await assertFails(getDoc(doc(await asUser(NOMSA), SAMS_DAY)));
    await assertFails(
      getDocs(collection(await asUser(NOMSA), `${HOME}/locationTrails/${SAM_MEMBER}/days`)),
    );
  });

  it('denies anybody writing somebody else"s day, the admin included', async () => {
    const path = `${HOME}/locationTrails/${LERATO_MEMBER}/trailDays/${DAY}`;
    await assertFails(setDoc(doc(await asUser(SAM), path), aDayOf(points(3))));
    await assertFails(setDoc(doc(await asUser(STRANGER), SAMS_DAY), aDayOf(points(3))));
  });

  it('denies a free or lapsed household keeping history', async () => {
    await clearData();
    await givenTheParkers(false);
    await assertFails(setDoc(doc(await asUser(SAM), SAMS_DAY), aDayOf(points(3))));
  });

  it('denies a day id that is not a date', async () => {
    const path = `${HOME}/locationTrails/${SAM_MEMBER}/trailDays/yesterday`;
    await assertFails(setDoc(doc(await asUser(SAM), path), aDayOf(points(3))));
  });

  it('denies more than 120 points in one write', async () => {
    await assertFails(setDoc(doc(await asUser(SAM), SAMS_DAY), aDayOf(points(121))));
  });

  it('adds a flush with arrayUnion once 30 seconds have passed', async () => {
    await givenSamsDay(100, 60_000);
    await assertSucceeds(
      updateDoc(doc(await asUser(SAM), SAMS_DAY), {
        points: arrayUnion(...points(20, 100)),
        updatedAt: serverTimestamp(),
        expiresAt: Timestamp.fromMillis(Date.now() + 30 * aDay),
      }),
    );
  });

  it('denies a flush inside 30 seconds of the last', async () => {
    await givenSamsDay(100, 5_000);
    await assertFails(
      updateDoc(doc(await asUser(SAM), SAMS_DAY), {
        points: arrayUnion(...points(5, 100)),
        updatedAt: serverTimestamp(),
        expiresAt: Timestamp.fromMillis(Date.now() + 30 * aDay),
      }),
    );
  });

  it('denies a flush that removes points, adds more than 120, or passes 3,000', async () => {
    const db = await asUser(SAM);
    await givenSamsDay(100, 60_000);
    await assertFails(setDoc(doc(db, SAMS_DAY), aDayOf(points(50))));
    await assertFails(
      updateDoc(doc(db, SAMS_DAY), {
        points: arrayUnion(...points(121, 100)),
        updatedAt: serverTimestamp(),
        expiresAt: Timestamp.fromMillis(Date.now() + 30 * aDay),
      }),
    );
    await givenSamsDay(2950, 60_000);
    await assertFails(
      updateDoc(doc(db, SAMS_DAY), {
        points: arrayUnion(...points(60, 2950)),
        updatedAt: serverTimestamp(),
        expiresAt: Timestamp.fromMillis(Date.now() + 30 * aDay),
      }),
    );
  });

  it('denies an expiry that is not thirty days out, and a field nobody named', async () => {
    const db = await asUser(SAM);
    await assertFails(
      setDoc(doc(db, SAMS_DAY), {
        ...aDayOf(points(3)),
        expiresAt: Timestamp.fromMillis(Date.now() + 365 * aDay),
      }),
    );
    await assertFails(setDoc(doc(db, SAMS_DAY), { ...aDayOf(points(3)), name: 'Sam' }));
  });

  it('lets a member clear their own history and an admin clear anybody"s', async () => {
    await givenSamsDay(10, 60_000);
    await assertFails(deleteDoc(doc(await asUser(LERATO), SAMS_DAY)));
    await assertSucceeds(deleteDoc(doc(await asUser(SAM), SAMS_DAY)));
  });
});

describe('locationTrails/{memberId}/placeEvents/{eventId}', () => {
  beforeEach(async () => {
    await clearData();
    await givenTheParkers(true);
  });

  it('lets a member say they arrived at a place', async () => {
    await assertSucceeds(setDoc(doc(await asUser(SAM), `${SAMS_EVENTS}/e1`), anEvent()));
  });

  it('denies an event for a place that does not exist, or of an unknown kind', async () => {
    const db = await asUser(SAM);
    await assertFails(setDoc(doc(db, `${SAMS_EVENTS}/e1`), anEvent({ placeId: 'moon' })));
    await assertFails(setDoc(doc(db, `${SAMS_EVENTS}/e2`), anEvent({ kind: 'teleport' })));
  });

  it('denies an event in somebody else"s name, a back-dated one, and changing one', async () => {
    const lerato = `${HOME}/locationTrails/${LERATO_MEMBER}/placeEvents/e1`;
    await assertFails(setDoc(doc(await asUser(SAM), lerato), anEvent()));
    await assertFails(
      setDoc(doc(await asUser(SAM), `${SAMS_EVENTS}/e1`), anEvent({ at: new Date('2000-01-01') })),
    );
    await givenData(async (db: Firestore) => {
      await setDoc(doc(db, `${SAMS_EVENTS}/e9`), { ...anEvent(), at: Timestamp.now() });
    });
    await assertFails(updateDoc(doc(await asUser(SAM), `${SAMS_EVENTS}/e9`), { kind: 'leave' }));
  });

  it('denies a free household', async () => {
    await clearData();
    await givenTheParkers(false);
    await assertFails(setDoc(doc(await asUser(SAM), `${SAMS_EVENTS}/e1`), anEvent()));
  });

  it('lets family read events and denies a helper without the grant and a stranger', async () => {
    await givenData(async (db: Firestore) => {
      await setDoc(doc(db, `${SAMS_EVENTS}/e9`), { ...anEvent(), at: Timestamp.now() });
    });
    await assertSucceeds(getDoc(doc(await asUser(LERATO), `${SAMS_EVENTS}/e9`)));
    await assertFails(getDoc(doc(await asUser(NOMSA), `${SAMS_EVENTS}/e9`)));
    await assertFails(getDocs(collection(await asUser(STRANGER), SAMS_EVENTS)));
  });
});

describe('places/{placeId}', () => {
  beforeEach(async () => {
    await clearData();
    await givenTheParkers(true);
  });

  it('lets family add and change a place, and anybody with view read them', async () => {
    const db = await asUser(LERATO);
    await assertSucceeds(setDoc(doc(db, `${PLACES}/home`), aPlace({ name: 'Home', icon: 'home' })));
    await assertSucceeds(getDocs(collection(await asUser(SAM), PLACES)));
  });

  it('denies somebody who may only look deleting or changing one', async () => {
    await givenData(async (db: Firestore) => {
      await updateDoc(doc(db, HOME), { [`access.${NOMSA}`]: { location: 'view' } });
    });
    const db = await asUser(NOMSA);
    await assertSucceeds(getDocs(collection(db, PLACES)));
    await assertFails(deleteDoc(doc(db, `${PLACES}/school`)));
    await assertFails(setDoc(doc(db, `${PLACES}/school`), aPlace({ name: 'Moved' })));
  });

  it('denies a helper without the grant reading or adding one', async () => {
    const db = await asUser(NOMSA);
    await assertFails(getDocs(collection(db, PLACES)));
    await assertFails(setDoc(doc(db, `${PLACES}/home`), aPlace()));
  });

  it('denies a free household adding one, and lets it delete what it has', async () => {
    await clearData();
    await givenTheParkers(false);
    const db = await asUser(LERATO);
    await assertFails(setDoc(doc(db, `${PLACES}/home`), aPlace()));
    await assertSucceeds(deleteDoc(doc(db, `${PLACES}/school`)));
  });

  it('denies a radius outside 75–500 m, an empty or long name, an unknown icon', async () => {
    const db = await asUser(LERATO);
    for (const bad of [
      { radiusMetres: 50 },
      { radiusMetres: 501 },
      { radiusMetres: 150.5 },
      { name: '' },
      { name: 'x'.repeat(41) },
      { icon: 'castle' },
      { alerts: { arrive: 'yes', leave: false } },
      { alerts: { arrive: true, leave: false, sms: true } },
      { centre: { lat: 1, lng: 2 } },
      { owner: SAM },
    ]) {
      await assertFails(setDoc(doc(db, `${PLACES}/bad`), aPlace(bad)));
    }
  });
});
