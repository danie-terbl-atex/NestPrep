import { afterAll, beforeAll, beforeEach, describe, expect, it } from 'vitest';

import { adminDb, callAs, clearFirestore, signUp } from './emulator_harness';
import {
  CalendarServer,
  type HouseholdOfTwo,
  calendarOf,
  expectRefusal,
  householdOfTwo,
  syncedTitles,
} from './calendar_sync_fixture';

/**
 * The calendar sync callables, over HTTP with real ID tokens (BE-14): who may
 * connect, sync and disconnect, and a calendar link read end to end from a
 * server on this machine (calendar ADR-0003). Google and Microsoft are not
 * configured in the emulator, which is exactly the state the unconfigured
 * tests are about; their exchange and refresh are unit-tested against fakes.
 */
const server = new CalendarServer();
let link: string;
let home: HouseholdOfTwo;

beforeAll(async () => {
  link = await server.start();
});

afterAll(async () => {
  await server.stop();
});

beforeEach(async () => {
  await clearFirestore();
  server.status = 200;
  server.body = calendarOf(
    { uid: 'fete', title: 'School fete', offsetDays: 3 },
    { uid: 'match', title: 'Netball match', offsetDays: 10 },
  );
  home = await householdOfTwo();
});

interface Connected {
  connectionId: string;
  status: string;
  eventCount: number;
}

function connectLink(): Promise<Connected> {
  return callAs<Connected>(home.thandi, 'connectCalendarLink', {
    householdId: home.householdId,
    url: link,
  });
}

describe('listCalendarProviders', () => {
  it('says which providers are set up — none, in the emulator', async () => {
    expect(
      await callAs(home.thandi, 'listCalendarProviders', { householdId: home.householdId }),
    ).toEqual({ google: false, microsoft: false });
  });

  it('refuses somebody outside the household, and nobody at all', async () => {
    await expectRefusal(
      callAs(await signUp(), 'listCalendarProviders', { householdId: home.householdId }),
      'notAMember',
    );
    await expectRefusal(
      callAs(null, 'listCalendarProviders', { householdId: home.householdId }),
      'notSignedIn',
    );
  });
});

describe('startCalendarConnection', () => {
  it('says a provider with no OAuth client is not set up, rather than failing', async () => {
    await expectRefusal(
      callAs(home.sam, 'startCalendarConnection', {
        householdId: home.householdId,
        provider: 'google',
      }),
      'providerNotConfigured',
    );
  });
});

describe('connectCalendarLink', () => {
  it('reads the calendar, files it under the member, and keeps the link out of sight', async () => {
    const connected = await connectLink();
    expect(connected).toMatchObject({ status: 'connected', eventCount: 2 });

    const connection = await adminDb()
      .collection('households')
      .doc(home.householdId)
      .collection('calendarConnections')
      .doc(connected.connectionId)
      .get();
    expect(connection.get('provider')).toBe('ics');
    expect(connection.get('ownerUid')).toBe(home.thandi.uid);
    expect(connection.get('accountLabel')).toBe('127.0.0.1');
    expect(JSON.stringify(connection.data())).not.toContain('family.ics');

    const secret = await adminDb()
      .collection('calendarConnectionSecrets')
      .doc(connected.connectionId)
      .get();
    expect(secret.get('credential')).toBe(link);
    expect(await syncedTitles(home.householdId)).toEqual(['Netball match', 'School fete']);
  });

  it('refuses a page that is not a calendar, and a link that is not a link', async () => {
    server.body = '<html><body>Sign in to iCloud</body></html>';
    await expectRefusal(connectLink(), 'notACalendarLink');
    await expectRefusal(
      callAs(home.thandi, 'connectCalendarLink', {
        householdId: home.householdId,
        url: 'ftp://example.com/c.ics',
      }),
      'notACalendarLink',
    );
  });

  it('says so when the link cannot be reached', async () => {
    server.status = 503;
    await expectRefusal(connectLink(), 'calendarLinkUnreachable');
  });

  it('refuses somebody outside the household', async () => {
    await expectRefusal(
      callAs(await signUp(), 'connectCalendarLink', { householdId: home.householdId, url: link }),
      'notAMember',
    );
  });
});

describe('syncCalendarConnection', () => {
  it('brings in what changed and lets go of what went', async () => {
    const { connectionId } = await connectLink();
    server.body = calendarOf(
      { uid: 'match', title: 'Netball final', offsetDays: 10 },
      { uid: 'swim', title: 'Swimming gala', offsetDays: 12 },
    );
    expect(
      await callAs(home.thandi, 'syncCalendarConnection', {
        householdId: home.householdId,
        connectionId,
      }),
    ).toEqual({ status: 'connected', eventCount: 2 });
    expect(await syncedTitles(home.householdId)).toEqual(['Netball final', 'Swimming gala']);
  });

  it('leaves the connection saying what went wrong, and its events as they were', async () => {
    const { connectionId } = await connectLink();
    server.body = 'not a calendar any more';
    expect(
      await callAs(home.thandi, 'syncCalendarConnection', {
        householdId: home.householdId,
        connectionId,
      }),
    ).toMatchObject({ status: 'notACalendar' });
    expect(await syncedTitles(home.householdId)).toHaveLength(2);
  });

  it('is for the person who connected it or an admin, not anybody else', async () => {
    const { connectionId } = await callAs<Connected>(home.sam, 'connectCalendarLink', {
      householdId: home.householdId,
      url: link,
    });
    await expectRefusal(
      callAs(home.thandi, 'syncCalendarConnection', {
        householdId: home.householdId,
        connectionId,
      }),
      'notYourConnection',
    );
    await expectRefusal(
      callAs(home.sam, 'syncCalendarConnection', {
        householdId: home.householdId,
        connectionId: 'nope',
      }),
      'connectionNotFound',
    );
  });
});

describe('disconnectCalendar', () => {
  it('takes away the connection, its credential and every event it brought', async () => {
    const { connectionId } = await connectLink();
    // An admin may disconnect somebody else's calendar.
    expect(
      await callAs(home.sam, 'disconnectCalendar', { householdId: home.householdId, connectionId }),
    ).toEqual({ removed: 2 });
    expect(await syncedTitles(home.householdId)).toEqual([]);
    const secret = await adminDb().collection('calendarConnectionSecrets').doc(connectionId).get();
    expect(secret.exists).toBe(false);
  });

  it('refuses a member who neither connected it nor is an admin', async () => {
    const { connectionId } = await callAs<Connected>(home.sam, 'connectCalendarLink', {
      householdId: home.householdId,
      url: link,
    });
    await expectRefusal(
      callAs(home.thandi, 'disconnectCalendar', { householdId: home.householdId, connectionId }),
      'notYourConnection',
    );
    expect(await syncedTitles(home.householdId)).toHaveLength(2);
  });
});
