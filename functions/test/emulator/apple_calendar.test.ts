import type { DocumentReference } from 'firebase-admin/firestore';
import { beforeEach, describe, expect, it } from 'vitest';

import { calendarSourcesFor } from '../../src/calendar_sync/calendar_sources';
import { FirestoreSyncStore } from '../../src/calendar_sync/firestore_sync_store';
import { IcsCalendar } from '../../src/calendar_sync/ics_calendar';
import { syncOldestConnections } from '../../src/calendar_sync/sync_calendars_on_schedule';
import type { HttpClient } from '../../src/shared/http_client';
import { adminDb, callAs, clearFirestore } from './emulator_harness';
import {
  type HouseholdOfTwo,
  expectRefusal,
  householdOfTwo,
  syncedTitles,
} from './calendar_sync_fixture';

/**
 * Apple Calendar, pushed from the member's iPhone: one connection per member,
 * no credential, the same diff as every other source, and a disconnect that
 * sticks even when the phone pushes again.
 */
let home: HouseholdOfTwo;

beforeEach(async () => {
  await clearFirestore();
  home = await householdOfTwo();
});

interface Pushed {
  connectionId: string;
  status: string;
  eventCount: number;
}

const inDays = (days: number, hour: number): number => {
  const day = new Date(Date.now() + days * 86_400_000);
  day.setUTCHours(hour, 0, 0, 0);
  return day.getTime();
};

const dentist = {
  id: 'dentist',
  title: 'Dentist',
  allDay: false,
  start: inDays(3, 8),
  end: inDays(3, 9),
};
const halfTerm = {
  id: 'half-term',
  title: 'Half term',
  allDay: true,
  startDate: new Date(Date.now() + 10 * 86_400_000).toISOString().slice(0, 10),
  endDateExclusive: new Date(Date.now() + 15 * 86_400_000).toISOString().slice(0, 10),
};

function push(link: boolean, occurrences: unknown[], user = home.thandi): Promise<Pushed> {
  return callAs<Pushed>(user, 'pushAppleCalendar', {
    householdId: home.householdId,
    link,
    occurrences,
  });
}

function connectionDoc(connectionId: string): DocumentReference {
  return adminDb()
    .collection('households')
    .doc(home.householdId)
    .collection('calendarConnections')
    .doc(connectionId);
}

describe('pushAppleCalendar', () => {
  it('links the member’s iPhone calendars and brings their events in', async () => {
    const pushed = await push(true, [dentist, halfTerm]);
    expect(pushed).toMatchObject({ status: 'connected', eventCount: 2 });
    expect(pushed.connectionId).toMatch(/^apple_/);
    expect(await syncedTitles(home.householdId)).toEqual(['Dentist', 'Half term']);
    const connection = await connectionDoc(pushed.connectionId).get();
    expect(connection.data()).toMatchObject({
      provider: 'apple',
      ownerUid: home.thandi.uid,
      accountLabel: '',
      eventCount: 2,
    });
    expect(
      (await adminDb().collection('calendarConnectionSecrets').doc(pushed.connectionId).get())
        .exists,
    ).toBe(false);
  });

  it('is one connection however often, and from however many phones, it is pushed', async () => {
    const first = await push(true, [dentist]);
    const second = await push(true, [dentist, halfTerm]);
    expect(second.connectionId).toBe(first.connectionId);
    const connections = await adminDb()
      .collection('households')
      .doc(home.householdId)
      .collection('calendarConnections')
      .get();
    expect(connections.size).toBe(1);
  });

  it('writes what changed and lets go of what the phone no longer has', async () => {
    await push(true, [dentist, halfTerm]);
    const pushed = await push(false, [{ ...dentist, title: 'Dentist (moved)' }]);
    expect(pushed.eventCount).toBe(1);
    expect(await syncedTitles(home.householdId)).toEqual(['Dentist (moved)']);
  });

  it('keeps only what falls in the family week’s window', async () => {
    const lastYear = { ...dentist, id: 'old', start: inDays(-300, 8), end: inDays(-300, 9) };
    expect((await push(true, [dentist, lastYear])).eventCount).toBe(1);
  });

  it('never makes a connection without being asked to link', async () => {
    await expectRefusal(push(false, [dentist]), 'connectionNotFound');
  });

  it('tells a phone whose calendar was disconnected elsewhere, instead of bringing it back', async () => {
    const { connectionId } = await push(true, [dentist]);
    await callAs(home.sam, 'disconnectCalendar', { householdId: home.householdId, connectionId });
    await expectRefusal(push(false, [dentist]), 'connectionNotFound');
    expect(await syncedTitles(home.householdId)).toEqual([]);
  });

  it('refuses an account that does not own the member’s connection', async () => {
    const { connectionId } = await push(true, [dentist]);
    await connectionDoc(connectionId).update({ ownerUid: 'somebody-else' });
    await expectRefusal(push(false, [dentist]), 'notYourConnection');
  });

  it('is left alone by Sync now and by the schedule, which cannot read an iPhone', async () => {
    const { connectionId } = await push(true, [dentist, halfTerm]);
    await callAs(home.thandi, 'syncCalendarConnection', {
      householdId: home.householdId,
      connectionId,
    });
    const store = adminDb();
    const http: HttpClient = {
      send: () => Promise.reject(new Error('no network in this test')),
    };
    const sources = calendarSourcesFor(
      {},
      http,
      new IcsCalendar(http, () => Promise.resolve([]), true),
    );
    await syncOldestConnections(store, {
      store: new FirestoreSyncStore(store),
      sources,
      now: () => new Date(),
    });
    expect((await connectionDoc(connectionId).get()).data()).toMatchObject({
      status: 'connected',
      eventCount: 2,
    });
    expect(await syncedTitles(home.householdId)).toEqual(['Dentist', 'Half term']);
  });
});
