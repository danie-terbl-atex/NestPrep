import { Timestamp, type DocumentReference } from 'firebase-admin/firestore';
import { beforeEach, describe, expect, it } from 'vitest';

import { ASSISTANT_WRITES } from '../../src/assistants/mcp/activity_log';
import { EVENT_KEYS, EXCEPTION_KEYS } from '../../src/assistants/mcp/event_documents';
import { ASSISTANT_TOOLS } from '../../src/assistants/mcp/tools';
import { deleteEvent, updateEvent } from '../../src/assistants/mcp/tools/change_event';
import { createEvent } from '../../src/assistants/mcp/tools/create_event';
import { getHousehold } from '../../src/assistants/mcp/tools/get_household';
import { listEvents } from '../../src/assistants/mcp/tools/list_events';
import { rateLimitId } from '../../src/shared/rate_limit';
import { RECURRENCE_KEYS, weeklyOn } from '../recurrence_shape';
import {
  EMMA,
  HOUSEHOLD,
  MIA,
  NOW,
  PAT,
  SAM,
  STRANGER,
  TODAY,
  acceptingOnly,
  bearer,
  exchange,
  givenTheOakStreetNest,
  modern,
  principalFor,
  rpc,
} from './assistants_mcp_fixture';
import { adminDb, clearFirestore } from './emulator_harness';

/**
 * The calendar tools against a real Firestore (assistants ADR-0001,
 * ADR-0005): what they write is the app's own document, field by field, in
 * the caller's name and the server's time, with one activity line beside
 * it; what they refuse is what the rules refuse, and what only a server can.
 */

const household = (): DocumentReference => adminDb().collection('households').doc(HOUSEHOLD);
const sam = principalFor(SAM);
const pat = principalFor(PAT);

async function eventDoc(id: string): Promise<Record<string, unknown>> {
  return (await household().collection('events').doc(id).get()).data() ?? {};
}

async function activity(): Promise<Record<string, unknown>[]> {
  return (await household().collection('assistantActivity').get()).docs.map((doc) => doc.data());
}

/** Saturday swimming, every week, added in the app by Pat. */
async function givenSwimming(): Promise<void> {
  await household()
    .collection('events')
    .doc('swimming')
    .set({
      title: 'Swimming',
      note: null,
      date: '2026-10-31',
      startMinute: 540,
      endMinute: 600,
      recurrence: weeklyOn([6]),
      memberIds: [EMMA],
      createdBy: PAT.member,
      createdAt: Timestamp.fromDate(new Date('2026-10-01T08:00:00Z')),
    });
}

beforeEach(async () => {
  await clearFirestore();
  await givenTheOakStreetNest();
});

describe('get_household', () => {
  it("names the household, today's date in its zone, and each member as adult or child", async () => {
    const answer = await getHousehold.run(adminDb(), sam, {}, NOW);
    expect(answer).toEqual({
      household: {
        id: HOUSEHOLD,
        name: 'The Oak Street Nest',
        time_zone: 'Africa/Johannesburg',
        today: TODAY,
        weekday: 'Thursday',
      },
      you: { member_id: SAM.member, first_name: 'Sam' },
      members: [
        { id: EMMA, first_name: 'Emma', kind: 'child' },
        { id: MIA, first_name: 'Mia', kind: 'child' },
        { id: 'm-nomsa', first_name: 'Nomsa', kind: 'adult' },
        { id: PAT.member, first_name: 'Pat', kind: 'adult' },
        { id: SAM.member, first_name: 'Sam', kind: 'adult' },
        { id: 'm-thandi', first_name: 'Thandi', kind: 'adult' },
      ],
      connection: {
        assistant: 'claude',
        may: ['household:read', 'calendar:read', 'calendar:write', 'lists:read', 'lists:write'],
      },
    });
  });

  it('carries no birthday, allergy, surname or role', async () => {
    const text = JSON.stringify(await getHousehold.run(adminDb(), sam, {}, NOW));
    for (const leak of ['2019-03-14', 'nuts', 'Parker', 'Dlamini', 'admin', 'helper', 'carer']) {
      expect(text).not.toContain(leak);
    }
  });

  it("today is the household's, not the server's: 23:30 UTC is already tomorrow in Johannesburg", async () => {
    const late = new Date('2026-10-29T23:30:00Z');
    const answer = await getHousehold.run(adminDb(), sam, {}, late);
    expect(answer.household.today).toBe('2026-10-30');
    expect(answer.household.weekday).toBe('Friday');
  });
});

describe('create_event', () => {
  it("writes exactly the app's document, in the caller's name, with the server's time and the assistant", async () => {
    const answer = await createEvent.run(
      adminDb(),
      sam,
      {
        title: "Emma's party",
        date: '2026-11-07',
        start_time: '14:00',
        end_time: '16:30',
        note: '12 Oak Street; bring a swimsuit',
        member_ids: [EMMA, SAM.member, EMMA],
        confirm_duplicate: false,
      },
      NOW,
    );
    const stored = await eventDoc(answer.event.id);
    expect(Object.keys(stored).sort()).toEqual([...EVENT_KEYS, 'createdVia'].sort());
    expect(stored).toMatchObject({
      title: "Emma's party",
      note: '12 Oak Street; bring a swimsuit',
      date: '2026-11-07',
      startMinute: 840,
      endMinute: 990,
      recurrence: null,
      memberIds: [EMMA, SAM.member],
      createdBy: SAM.member,
      createdVia: 'claude',
    });
    expect(stored['createdAt']).toBeInstanceOf(Timestamp);
    expect(answer).toEqual({
      event: {
        id: answer.event.id,
        title: "Emma's party",
        note: '12 Oak Street; bring a swimsuit',
        date: '2026-11-07',
        all_day: false,
        start_time: '14:00',
        end_time: '16:30',
        recurrence: null,
        member_ids: [EMMA, SAM.member],
        created_by: SAM.member,
        created_via: 'claude',
      },
    });
  });

  it('writes one activity line beside it, ids only', async () => {
    const answer = await createEvent.run(
      adminDb(),
      sam,
      { title: 'Dentist', date: '2026-11-02', member_ids: [], confirm_duplicate: false },
      NOW,
    );
    const lines = await activity();
    expect(lines).toHaveLength(1);
    const [line] = lines;
    expect(Object.keys(line ?? {}).sort()).toEqual(
      ['at', 'expiresAt', 'grantId', 'memberId', 'target', 'tool', 'via'].sort(),
    );
    expect(line).toMatchObject({
      grantId: sam.grantId,
      memberId: SAM.member,
      via: 'claude',
      tool: 'create_event',
      target: { kind: 'event', id: answer.event.id },
    });
    expect((line?.['expiresAt'] as Timestamp).toMillis()).toBe(NOW.getTime() + 90 * 86_400_000);
    expect(JSON.stringify(line)).not.toContain('Dentist');
  });

  it('an all-day event stores both times as null, as the app does', async () => {
    const answer = await createEvent.run(
      adminDb(),
      sam,
      { title: 'Half term', date: '2026-11-02', member_ids: [], confirm_duplicate: false },
      NOW,
    );
    expect(await eventDoc(answer.event.id)).toMatchObject({
      startMinute: null,
      endMinute: null,
      note: null,
      memberIds: [],
    });
    expect(answer.event.all_day).toBe(true);
  });

  it("stores a repeat in the Dart rule's exact shape", async () => {
    const answer = await createEvent.run(
      adminDb(),
      sam,
      {
        title: 'Piano',
        date: '2026-11-03',
        start_time: '15:00',
        member_ids: [EMMA],
        recurrence: { frequency: 'weekly', interval: 2, weekdays: [4, 2], until: '2027-03-31' },
        confirm_duplicate: false,
      },
      NOW,
    );
    const recurrence = (await eventDoc(answer.event.id))['recurrence'] as Record<string, unknown>;
    expect(Object.keys(recurrence).sort()).toEqual([...RECURRENCE_KEYS].sort());
    expect(recurrence).toEqual({
      frequency: 'weekly',
      interval: 2,
      weekdays: [2, 4],
      until: '2027-03-31',
    });
  });

  it('refuses members of another household, and ids that are nobody', async () => {
    for (const memberId of [STRANGER, 'm-nobody']) {
      await expect(
        createEvent.run(
          adminDb(),
          sam,
          { title: 'Party', date: '2026-11-07', member_ids: [memberId], confirm_duplicate: false },
          NOW,
        ),
      ).rejects.toMatchObject({ kind: 'badRequest', reason: 'unknownMember' });
    }
    expect((await household().collection('events').get()).size).toBe(0);
  });

  it('refuses an end with no start, and a repeat that ends before it starts', async () => {
    await expect(
      createEvent.run(
        adminDb(),
        sam,
        {
          title: 'x',
          date: '2026-11-07',
          end_time: '10:00',
          member_ids: [],
          confirm_duplicate: false,
        },
        NOW,
      ),
    ).rejects.toMatchObject({ reason: 'endWithoutStart' });
    await expect(
      createEvent.run(
        adminDb(),
        sam,
        {
          title: 'x',
          date: '2026-11-07',
          member_ids: [],
          recurrence: { frequency: 'daily', interval: 1, weekdays: [], until: '2026-11-01' },
          confirm_duplicate: false,
        },
        NOW,
      ),
    ).rejects.toMatchObject({ reason: 'untilBeforeDate' });
  });

  it('refuses at the edge what the Dart rule could not expand, a day that is not a day, a time that is not a time', () => {
    const bad = [
      { title: 'x', date: '2026-02-30' },
      { title: 'x', date: '07/11/2026' },
      { title: 'x', date: '2026-11-07', start_time: '24:00' },
      { title: 'x', date: '2026-11-07', start_time: '9am' },
      { title: '', date: '2026-11-07' },
      { title: 'x'.repeat(201), date: '2026-11-07' },
      { title: 'x', date: '2026-11-07', recurrence: { frequency: 'weekly', interval: 0 } },
      { title: 'x', date: '2026-11-07', recurrence: { frequency: 'weekly', interval: 367 } },
      { title: 'x', date: '2026-11-07', recurrence: { frequency: 'weekly', weekdays: [0] } },
      { title: 'x', date: '2026-11-07', recurrence: { frequency: 'weekly', weekdays: [1, 1] } },
      { title: 'x', date: '2026-11-07', recurrence: { frequency: 'daily', weekdays: [1] } },
      { title: 'x', date: '2026-11-07', recurrence: { frequency: 'yearly' } },
    ];
    for (const args of bad) {
      expect(createEvent.input.safeParse(args).success, JSON.stringify(args)).toBe(false);
    }
  });

  it('cannot be told who created it: an extra field is refused, not ignored', async () => {
    const tool = ASSISTANT_TOOLS.find((candidate) => candidate.name === 'create_event');
    await expect(
      tool?.call(
        adminDb(),
        sam,
        { title: 'Party', date: '2026-11-07', created_by: PAT.member, createdVia: 'chatgpt' },
        NOW,
      ),
    ).rejects.toThrow();
    const call = modern('tools/call', {
      name: 'create_event',
      arguments: { title: 'Party', date: '2026-11-07', created_by: PAT.member },
    });
    const reply = await exchange(acceptingOnly('t', sam), {
      body: call.body,
      headers: { ...call.headers, ...bearer('t') },
    });
    expect((rpc(reply).result as { isError: boolean }).isError).toBe(true);
    expect((await household().collection('events').get()).size).toBe(0);
  });

  it("the via is the connection's, and the creator the caller's member, whoever the assistant says", async () => {
    const answer = await createEvent.run(
      adminDb(),
      { ...pat, via: 'chatgpt' },
      { title: 'Dentist', date: '2026-11-02', member_ids: [], confirm_duplicate: false },
      NOW,
    );
    expect(await eventDoc(answer.event.id)).toMatchObject({
      createdBy: PAT.member,
      createdVia: 'chatgpt',
    });
  });

  describe('the duplicate guard', () => {
    it('the same title, any case or spacing, on the same day is possible_duplicate', async () => {
      await createEvent.run(
        adminDb(),
        sam,
        { title: 'Dentist', date: '2026-11-02', member_ids: [], confirm_duplicate: false },
        NOW,
      );
      await expect(
        createEvent.run(
          adminDb(),
          sam,
          { title: '  dentist ', date: '2026-11-02', member_ids: [], confirm_duplicate: false },
          NOW,
        ),
      ).rejects.toMatchObject({ kind: 'conflict', reason: 'possible_duplicate' });
      expect((await household().collection('events').get()).size).toBe(1);
    });

    it('confirm_duplicate writes the second one', async () => {
      await createEvent.run(
        adminDb(),
        sam,
        { title: 'Dentist', date: '2026-11-02', member_ids: [], confirm_duplicate: false },
        NOW,
      );
      await createEvent.run(
        adminDb(),
        sam,
        { title: 'Dentist', date: '2026-11-02', member_ids: [], confirm_duplicate: true },
        NOW,
      );
      expect((await household().collection('events').get()).size).toBe(2);
    });

    it('a repeat that lands on the day counts; a skipped occurrence of it does not; another day does not', async () => {
      await givenSwimming();
      await expect(
        createEvent.run(
          adminDb(),
          sam,
          { title: 'swimming', date: '2026-11-07', member_ids: [], confirm_duplicate: false },
          NOW,
        ),
      ).rejects.toMatchObject({ reason: 'possible_duplicate' });
      await household().collection('eventExceptions').doc('swimming_2026-11-07').set({
        eventId: 'swimming',
        occurrenceDate: '2026-11-07',
        skippedBy: PAT.member,
        skippedAt: Timestamp.now(),
      });
      await createEvent.run(
        adminDb(),
        sam,
        { title: 'Swimming', date: '2026-11-07', member_ids: [], confirm_duplicate: false },
        NOW,
      );
      await createEvent.run(
        adminDb(),
        sam,
        { title: 'Swimming', date: '2026-11-08', member_ids: [], confirm_duplicate: false },
        NOW,
      );
    });

    it('reaches the assistant as a tool error that says how to confirm', async () => {
      await createEvent.run(
        adminDb(),
        sam,
        { title: 'Dentist', date: '2026-11-02', member_ids: [], confirm_duplicate: false },
        NOW,
      );
      const call = modern('tools/call', {
        name: 'create_event',
        arguments: { title: 'Dentist', date: '2026-11-02' },
      });
      const reply = await exchange(acceptingOnly('t', sam), {
        body: call.body,
        headers: { ...call.headers, ...bearer('t') },
      });
      const result = rpc(reply).result as { isError: boolean; content: { text: string }[] };
      expect(result.isError).toBe(true);
      expect(result.content[0]?.text).toMatch(/^possible_duplicate: .*confirm_duplicate: true/);
    });
  });

  it('60 writes an hour per connection, then rateLimited', async () => {
    await adminDb()
      .collection('rateLimits')
      .doc(rateLimitId(ASSISTANT_WRITES, sam.grantId))
      .set({
        rule: ASSISTANT_WRITES.name,
        windowStart: Timestamp.fromDate(new Date(NOW.getTime() - 60_000)),
        count: 60,
        expiresAt: Timestamp.fromDate(new Date(NOW.getTime() + 3_000_000)),
      });
    await expect(
      createEvent.run(
        adminDb(),
        sam,
        { title: 'Dentist', date: '2026-11-02', member_ids: [], confirm_duplicate: false },
        NOW,
      ),
    ).rejects.toMatchObject({ kind: 'rateLimited', reason: 'writeLimit' });
    await expect(
      createEvent.run(
        adminDb(),
        pat,
        { title: 'Dentist', date: '2026-11-02', member_ids: [], confirm_duplicate: false },
        NOW,
      ),
    ).resolves.toBeDefined();
  });
});

describe('list_events', () => {
  it('expands a repeat over the window, skipping skipped occurrences', async () => {
    await givenSwimming();
    await household().collection('eventExceptions').doc('swimming_2026-11-07').set({
      eventId: 'swimming',
      occurrenceDate: '2026-11-07',
      skippedBy: PAT.member,
      skippedAt: Timestamp.now(),
    });
    const answer = await listEvents.run(
      adminDb(),
      sam,
      { from: '2026-10-29', to: '2026-11-21' },
      NOW,
    );
    expect(answer.occurrences.map((occurrence) => occurrence.date)).toEqual([
      '2026-10-31',
      '2026-11-14',
      '2026-11-21',
    ]);
    expect(answer.occurrences[0]).toEqual({
      event_id: 'swimming',
      date: '2026-10-31',
      title: 'Swimming',
      note: null,
      all_day: false,
      start_time: '09:00',
      end_time: '10:00',
      member_ids: [EMMA],
      recurring: true,
      created_by: PAT.member,
      created_via: null,
    });
    expect(answer.truncated).toBe(false);
  });

  it('filters by member, keeping what is for everybody', async () => {
    await givenSwimming();
    await createEvent.run(
      adminDb(),
      sam,
      { title: 'Bins', date: '2026-10-30', member_ids: [], confirm_duplicate: false },
      NOW,
    );
    await createEvent.run(
      adminDb(),
      sam,
      { title: 'Gym', date: '2026-10-30', member_ids: [SAM.member], confirm_duplicate: false },
      NOW,
    );
    const answer = await listEvents.run(
      adminDb(),
      sam,
      { from: '2026-10-29', to: '2026-10-31', member_ids: [EMMA] },
      NOW,
    );
    expect(answer.occurrences.map((occurrence) => occurrence.title)).toEqual(['Bins', 'Swimming']);
  });

  it('orders all-day before timed, then by time', async () => {
    await createEvent.run(
      adminDb(),
      sam,
      {
        title: 'B late',
        date: '2026-10-30',
        start_time: '18:00',
        member_ids: [],
        confirm_duplicate: false,
      },
      NOW,
    );
    await createEvent.run(
      adminDb(),
      sam,
      {
        title: 'A early',
        date: '2026-10-30',
        start_time: '07:30',
        member_ids: [],
        confirm_duplicate: false,
      },
      NOW,
    );
    await createEvent.run(
      adminDb(),
      sam,
      { title: 'Z all day', date: '2026-10-30', member_ids: [], confirm_duplicate: false },
      NOW,
    );
    const answer = await listEvents.run(
      adminDb(),
      sam,
      { from: '2026-10-30', to: '2026-10-30' },
      NOW,
    );
    expect(answer.occurrences.map((occurrence) => occurrence.title)).toEqual([
      'Z all day',
      'A early',
      'B late',
    ]);
  });

  it('refuses a window over 62 days, and one that runs backwards', async () => {
    await expect(
      listEvents.run(adminDb(), sam, { from: '2026-11-01', to: '2027-01-02' }, NOW),
    ).rejects.toMatchObject({ reason: 'badWindow' });
    await expect(
      listEvents.run(adminDb(), sam, { from: '2026-11-01', to: '2026-10-31' }, NOW),
    ).rejects.toMatchObject({ reason: 'badWindow' });
    await expect(
      listEvents.run(adminDb(), sam, { from: '2026-11-01', to: '2027-01-01' }, NOW),
    ).resolves.toBeDefined();
  });
});

describe('update_event', () => {
  it('the creator changes their own event in only the keys that moved', async () => {
    const created = await createEvent.run(
      adminDb(),
      pat,
      {
        title: 'Dentist',
        date: '2026-11-02',
        start_time: '09:00',
        end_time: '09:45',
        member_ids: [],
        confirm_duplicate: false,
      },
      NOW,
    );
    const before = await eventDoc(created.event.id);
    const answer = await updateEvent.run(
      adminDb(),
      pat,
      { event_id: created.event.id, start_time: '10:00' },
      NOW,
    );
    const after = await eventDoc(created.event.id);
    expect(after).toEqual({ ...before, startMinute: 600, endMinute: 645 });
    expect(answer).toMatchObject({ changed: 'event', skipped_occurrence: null });
    expect(answer.event).toMatchObject({ start_time: '10:00', end_time: '10:45' });
  });

  it('a parent who did not create it is refused; an admin may', async () => {
    const created = await createEvent.run(
      adminDb(),
      sam,
      { title: 'Dentist', date: '2026-11-02', member_ids: [], confirm_duplicate: false },
      NOW,
    );
    await expect(
      updateEvent.run(adminDb(), pat, { event_id: created.event.id, title: 'Doctor' }, NOW),
    ).rejects.toMatchObject({ kind: 'forbidden', reason: 'notTheCreator' });
    await givenSwimming();
    await updateEvent.run(
      adminDb(),
      sam,
      { event_id: 'swimming', scope: 'series', title: 'Swim club' },
      NOW,
    );
    expect((await eventDoc('swimming'))['title']).toBe('Swim club');
  });

  it('a repeating event needs a scope', async () => {
    await givenSwimming();
    await expect(
      updateEvent.run(adminDb(), pat, { event_id: 'swimming', start_time: '10:00' }, NOW),
    ).rejects.toMatchObject({ reason: 'scopeNeeded' });
  });

  it("one occurrence moved: the app's skip for that day, and a one-off with the change", async () => {
    await givenSwimming();
    const answer = await updateEvent.run(
      adminDb(),
      pat,
      {
        event_id: 'swimming',
        scope: 'occurrence',
        occurrence_date: '2026-11-07',
        start_time: '10:00',
      },
      NOW,
    );
    const skip = (
      await household().collection('eventExceptions').doc('swimming_2026-11-07').get()
    ).data();
    expect(Object.keys(skip ?? {}).sort()).toEqual([...EXCEPTION_KEYS].sort());
    expect(skip).toMatchObject({
      eventId: 'swimming',
      occurrenceDate: '2026-11-07',
      skippedBy: PAT.member,
    });
    expect(skip?.['skippedAt']).toBeInstanceOf(Timestamp);
    const replacement = await eventDoc(answer.event.id);
    expect(Object.keys(replacement).sort()).toEqual([...EVENT_KEYS, 'createdVia'].sort());
    expect(replacement).toMatchObject({
      title: 'Swimming',
      date: '2026-11-07',
      startMinute: 600,
      endMinute: 660,
      recurrence: null,
      memberIds: [EMMA],
      createdBy: PAT.member,
      createdVia: 'claude',
    });
    expect((await eventDoc('swimming'))['startMinute']).toBe(540);
    expect(answer.skipped_occurrence).toBe('2026-11-07');
    const listed = await listEvents.run(
      adminDb(),
      pat,
      { from: '2026-11-07', to: '2026-11-07' },
      NOW,
    );
    expect(
      listed.occurrences.map((occurrence) => [occurrence.event_id, occurrence.start_time]),
    ).toEqual([[answer.event.id, '10:00']]);
  });

  it('refuses a day the series does not happen on, and one already skipped', async () => {
    await givenSwimming();
    await expect(
      updateEvent.run(
        adminDb(),
        pat,
        { event_id: 'swimming', scope: 'occurrence', occurrence_date: '2026-11-06', title: 'x' },
        NOW,
      ),
    ).rejects.toMatchObject({ reason: 'notAnOccurrence' });
    await deleteEvent.run(
      adminDb(),
      pat,
      { event_id: 'swimming', scope: 'occurrence', occurrence_date: '2026-11-07' },
      NOW,
    );
    await expect(
      updateEvent.run(
        adminDb(),
        pat,
        { event_id: 'swimming', scope: 'occurrence', occurrence_date: '2026-11-07', title: 'x' },
        NOW,
      ),
    ).rejects.toMatchObject({ reason: 'alreadySkipped' });
  });

  it("refuses an id that is nobody's event, and an empty change", async () => {
    await expect(
      updateEvent.run(adminDb(), sam, { event_id: 'nope', title: 'x' }, NOW),
    ).rejects.toMatchObject({ kind: 'notFound' });
    await expect(updateEvent.run(adminDb(), sam, { event_id: 'nope' }, NOW)).rejects.toMatchObject({
      reason: 'nothingToChange',
    });
  });

  it('member ids of another household are refused on update too', async () => {
    const created = await createEvent.run(
      adminDb(),
      sam,
      { title: 'Dentist', date: '2026-11-02', member_ids: [], confirm_duplicate: false },
      NOW,
    );
    await expect(
      updateEvent.run(adminDb(), sam, { event_id: created.event.id, member_ids: [STRANGER] }, NOW),
    ).rejects.toMatchObject({ reason: 'unknownMember' });
  });
});

describe('delete_event', () => {
  it('a parent who did not create it is refused, the creator and an admin may', async () => {
    const mine = await createEvent.run(
      adminDb(),
      pat,
      { title: 'Gym', date: '2026-11-02', member_ids: [], confirm_duplicate: false },
      NOW,
    );
    const samsEvent = await createEvent.run(
      adminDb(),
      sam,
      { title: 'Dentist', date: '2026-11-02', member_ids: [], confirm_duplicate: false },
      NOW,
    );
    await expect(
      deleteEvent.run(adminDb(), pat, { event_id: samsEvent.event.id }, NOW),
    ).rejects.toMatchObject({ reason: 'notTheCreator' });
    await expect(
      deleteEvent.run(adminDb(), pat, { event_id: mine.event.id }, NOW),
    ).resolves.toEqual({
      deleted: 'event',
      event_id: mine.event.id,
      occurrence_date: null,
    });
    await givenSwimming();
    await expect(
      deleteEvent.run(adminDb(), sam, { event_id: 'swimming', scope: 'series' }, NOW),
    ).resolves.toMatchObject({ deleted: 'series' });
    expect((await household().collection('events').doc('swimming').get()).exists).toBe(false);
  });

  it("one occurrence is the app's skip, and the series stays", async () => {
    await givenSwimming();
    await deleteEvent.run(
      adminDb(),
      pat,
      { event_id: 'swimming', scope: 'occurrence', occurrence_date: '2026-10-31' },
      NOW,
    );
    expect(
      (await household().collection('eventExceptions').doc('swimming_2026-10-31').get()).data(),
    ).toMatchObject({
      eventId: 'swimming',
      occurrenceDate: '2026-10-31',
      skippedBy: PAT.member,
    });
    expect((await household().collection('events').doc('swimming').get()).exists).toBe(true);
    const lines = await activity();
    expect(lines.map((line) => line['tool'])).toEqual(['delete_event']);
  });

  it('is marked destructive, as is every change that can overwrite or cut short what was there', () => {
    const destructive = ASSISTANT_TOOLS.filter((tool) => tool.annotations.destructiveHint).map(
      (tool) => tool.name,
    );
    expect(destructive).toEqual([
      'update_event',
      'delete_event',
      'update_grocery_item',
      'remove_grocery_items',
    ]);
  });
});
