import { afterAll, beforeAll, beforeEach, describe, expect, it } from 'vitest';

import { ROLE_DEFAULTS } from '../../src/household/access';
import { adminDb, callAs, clearFirestore } from './emulator_harness';
import { CalendarServer, calendarOf, expectRefusal, householdOfTwo } from './calendar_sync_fixture';

/**
 * What a helper's `calendar` grant lets them do with calendar sync (household
 * ADR-0003, calendar ADR-0003): `view` sees which calendars can be connected
 * and the household's feed link; bringing a calendar into the family week, or
 * changing one, is `edit`. A helper's defaults are `view`.
 */

const server = new CalendarServer();
let link = '';

beforeAll(async () => {
  link = await server.start();
});

afterAll(async () => {
  await server.stop();
});

beforeEach(async () => {
  await clearFirestore();
  server.body = calendarOf({ uid: 'fete', title: 'School fete', offsetDays: 3 });
  server.status = 200;
});

describe('a helper on the defaults — the calendar at view', () => {
  it('sees which calendars can be connected, and the feed link', async () => {
    const { thandi, householdId } = await householdOfTwo('helper');
    await expect(callAs(thandi, 'listCalendarProviders', { householdId })).resolves.toBeDefined();
    const feed = await callAs<{ url: string }>(thandi, 'shareCalendarFeed', { householdId });
    expect(feed.url).toMatch(/^https?:\/\//);
  });

  it('connects nothing into the family week', async () => {
    const { thandi, householdId } = await householdOfTwo('helper');
    await expectRefusal(
      callAs(thandi, 'connectCalendarLink', { householdId, url: link }),
      'calendarNotShared',
    );
    await expectRefusal(
      callAs(thandi, 'startCalendarConnection', { householdId, provider: 'google' }),
      'calendarNotShared',
    );
  });
});

describe('a helper a parent gave the calendar at edit', () => {
  it('connects a calendar like family does', async () => {
    const { sam, thandi, householdId } = await householdOfTwo('helper');
    const { memberId } = await thandiProfile(householdId);
    await callAs(sam, 'setMemberAccess', {
      householdId,
      memberId,
      access: { ...ROLE_DEFAULTS.helper, calendar: 'edit' },
    });
    await expect(
      callAs(thandi, 'connectCalendarLink', { householdId, url: link }),
    ).resolves.toBeDefined();
  });
});

describe('a helper the calendar is closed to', () => {
  it('is not even told which providers exist', async () => {
    const { sam, thandi, householdId } = await householdOfTwo('helper');
    const { memberId } = await thandiProfile(householdId);
    await callAs(sam, 'setMemberAccess', {
      householdId,
      memberId,
      access: { ...ROLE_DEFAULTS.helper, calendar: 'none' },
    });
    await expectRefusal(
      callAs(thandi, 'listCalendarProviders', { householdId }),
      'calendarNotShared',
    );
    await expectRefusal(callAs(thandi, 'shareCalendarFeed', { householdId }), 'calendarNotShared');
  });
});

/** The profile Thandi claimed, which is what a parent's grant is set on. */
async function thandiProfile(householdId: string): Promise<{ memberId: string }> {
  const found = await adminDb()
    .collection('households')
    .doc(householdId)
    .collection('members')
    .where('displayName', '==', 'Thandi')
    .limit(1)
    .get();
  const profile = found.docs[0];
  if (profile === undefined) throw new Error('the fixture made no Thandi');
  return { memberId: profile.id };
}
