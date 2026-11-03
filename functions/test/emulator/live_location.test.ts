import { FieldValue, GeoPoint, Timestamp } from 'firebase-admin/firestore';
import { beforeEach, describe, expect, it } from 'vitest';

import { adminDb, clearFirestore } from './emulator_harness';
import { HOME, MIA, PAT, SAM, givenTheHousehold, inbox } from './notifications_fixture';
import { eventually } from './product_analytics_fixture';

/**
 * A phone crossing one of the household's places (live-location ADR-0006):
 * `notifyPlaceEvent` tells everybody who can see the map, never the mover,
 * once per change, and only when the place asks for it.
 */

const SCHOOL = `${HOME}/places/school`;
const SAMS_EVENTS = `${HOME}/locationTrails/${SAM.member}/placeEvents`;
const thirtyDays = (): Timestamp => Timestamp.fromMillis(Date.now() + 30 * 24 * 3600 * 1000);

async function givenSchool(alerts: { arrive: boolean; leave: boolean }): Promise<void> {
  await adminDb()
    .doc(SCHOOL)
    .set({
      name: 'Parkhurst Primary',
      centre: new GeoPoint(-26.13, 28.07),
      radiusMetres: 150,
      icon: 'school',
      alerts,
      updatedAt: FieldValue.serverTimestamp(),
    });
}

async function samDoes(eventId: string, kind: 'arrive' | 'leave'): Promise<void> {
  await adminDb().doc(`${SAMS_EVENTS}/${eventId}`).set({
    placeId: 'school',
    kind,
    at: FieldValue.serverTimestamp(),
    expiresAt: thirtyDays(),
  });
}

async function places(): Promise<Record<string, unknown>[]> {
  return (await inbox()).filter((item) => item['category'] === 'places');
}

beforeEach(async () => {
  await clearFirestore();
  await givenTheHousehold({ withPhones: false });
});

describe('notifyPlaceEvent', () => {
  it('tells everybody who can see the map that Sam arrived, and not Sam', async () => {
    await givenSchool({ arrive: true, leave: false });
    await samDoes('e1', 'arrive');

    const items = await eventually(places, (found) => found.length >= 2);
    const told = items.map((item) => item['memberId']);
    expect(told).toContain(PAT.member);
    expect(told).toContain(MIA.member);
    expect(told).not.toContain(SAM.member);
    for (const item of items) {
      expect(item['detail']).toBe('Sam arrived at Parkhurst Primary');
      expect(item['target']).toEqual({ kind: 'whereWeAre', id: SAM.member });
    }
    const parent = items.find((item) => item['memberId'] === PAT.member);
    expect(parent?.['body']).toBe('Sam arrived at Parkhurst Primary');
    const kid = items.find((item) => item['memberId'] === MIA.member);
    expect(`${String(kid?.['title'])} ${String(kid?.['body'])}`).not.toMatch(/Sam|Parkhurst/);
  });

  it('says a repeat once: a flapping fence is not two arrivals', async () => {
    await givenSchool({ arrive: true, leave: true });
    await samDoes('e1', 'arrive');
    await eventually(places, (found) => found.length >= 2);
    const first = (await places()).length;
    await adminDb()
      .doc(`${HOME}/locationTrails/${SAM.member}`)
      .set({ lastPlaceEvents: { school: { kind: 'arrive', at: Date.now() - 10 * 60 * 1000 } } });

    await samDoes('e2', 'arrive');
    await samDoes('e3', 'leave');
    const after = await eventually(places, (found) => found.length >= first * 2);
    expect(after.filter((item) => String(item['id']).startsWith('place_e2_'))).toEqual([]);
    expect(after.some((item) => String(item['id']).startsWith('place_e3_'))).toBe(true);
  });

  it('tells an arrival after a missed exit, once the repeat window has passed', async () => {
    await givenSchool({ arrive: true, leave: true });
    await adminDb()
      .doc(`${HOME}/locationTrails/${SAM.member}`)
      .set({ lastPlaceEvents: { school: { kind: 'arrive', at: Date.now() - 20 * 3600 * 1000 } } });
    await samDoes('e7', 'arrive');
    const items = await eventually(places, (found) => found.length >= 2);
    expect(items.every((item) => String(item['id']).startsWith('place_e7_'))).toBe(true);
  });

  it('stays quiet when the place does not ask for that kind', async () => {
    await givenSchool({ arrive: false, leave: false });
    await samDoes('e1', 'arrive');
    await eventually(
      async () => (await adminDb().doc(`${HOME}/locationTrails/${SAM.member}`).get()).data(),
      (trail) => trail !== undefined,
    );
    expect(await places()).toEqual([]);
  });
});
