import { beforeEach, describe, expect, it } from 'vitest';

import { PROJECT_ID, REGION, adminDb, callAs, clearFirestore, signUp } from './emulator_harness';
import { type HouseholdOfTwo, expectRefusal, householdOfTwo } from './calendar_sync_fixture';

/**
 * The household's feed and the OAuth callback — the two calendar sync
 * Functions reached by a URL rather than a call (calendar ADR-0003).
 */
const FUNCTIONS_HOST = process.env['FUNCTIONS_EMULATOR_HOST'] ?? '127.0.0.1:5001';
const base = `http://${FUNCTIONS_HOST}/${PROJECT_ID}/${REGION}`;

let home: HouseholdOfTwo;

beforeEach(async () => {
  await clearFirestore();
  home = await householdOfTwo();
  await adminDb()
    .collection('households')
    .doc(home.householdId)
    .collection('events')
    .doc('soccer')
    .set({
      title: 'Soccer',
      note: 'bring the orange slices',
      date: '2026-09-29',
      startMinute: 1020,
      endMinute: 1080,
      recurrence: { frequency: 'weekly', interval: 1, weekdays: [2], until: null },
      memberIds: [],
      createdBy: 'm-sam',
      createdAt: new Date(),
    });
});

function shareFeed(user = home.thandi): Promise<{ url: string }> {
  return callAs<{ url: string }>(user, 'shareCalendarFeed', { householdId: home.householdId });
}

describe('shareCalendarFeed', () => {
  it('gives any member the same link every time', async () => {
    const first = await shareFeed();
    expect(first.url).toMatch(/calendarFeed\?token=[A-Za-z0-9_-]{43}$/);
    expect(await shareFeed(home.sam)).toEqual(first);
  });

  it('refuses somebody outside the household', async () => {
    await expectRefusal(
      callAs(await signUp(), 'shareCalendarFeed', { householdId: home.householdId }),
      'notAMember',
    );
  });
});

describe('calendarFeed', () => {
  it('serves the household’s events as a calendar, titles and times only', async () => {
    const response = await fetch((await shareFeed()).url);
    expect(response.status).toBe(200);
    expect(response.headers.get('content-type')).toContain('text/calendar');
    const body = await response.text();
    expect(body).toContain('SUMMARY:Soccer');
    expect(body).toContain('RRULE:FREQ=WEEKLY;INTERVAL=1;BYDAY=TU');
    expect(body).toContain('X-WR-CALNAME:The Parkers');
    expect(body).not.toContain('orange slices');
  });

  it('answers an unknown token with a plain 404', async () => {
    const response = await fetch(`${base}/calendarFeed?token=${'x'.repeat(43)}`);
    expect(response.status).toBe(404);
    expect(await response.text()).not.toContain('Soccer');
  });
});

describe('resetCalendarFeed', () => {
  it('is an admin’s, and the old link stops working the moment it happens', async () => {
    const old = await shareFeed();
    await expectRefusal(
      callAs(home.thandi, 'resetCalendarFeed', { householdId: home.householdId }),
      'notAnAdmin',
    );
    const fresh = await callAs<{ url: string }>(home.sam, 'resetCalendarFeed', {
      householdId: home.householdId,
    });
    expect(fresh.url).not.toBe(old.url);
    expect((await fetch(old.url)).status).toBe(404);
    expect((await fetch(fresh.url)).status).toBe(200);
    expect(await shareFeed()).toEqual(fresh);
  });
});

describe('calendarOAuthCallback', () => {
  it('turns a state it never issued into words, not an error', async () => {
    const response = await fetch(`${base}/calendarOAuthCallback?code=abc&state=${'s'.repeat(32)}`);
    expect(response.status).toBe(400);
    const page = await response.text();
    expect(page).toContain('That link has expired');
    expect(page).not.toMatch(/stack|Error:|invalid_grant/);
  });
});
