import { Timestamp } from 'firebase-admin/firestore';
import { HttpsError } from 'firebase-functions/v2/https';
import { describe, expect, it } from 'vitest';

import { ROLE_DEFAULTS } from '../../src/household/access';
import { parseInput } from '../../src/household/parse_input';
import { NANNY_REFUSALS } from '../../src/nanny_hub/errors';
import { hubEditorFrom, mayEndShift } from '../../src/nanny_hub/hub_caller';
import { endNannyShiftInput } from '../../src/nanny_hub/schemas';
import {
  SUMMARY_MOMENT_LIMIT,
  checklistProgress,
  summariseShift,
} from '../../src/nanny_hub/shift_summary';

/**
 * The rules a shift's end holds, tested where they live and without an
 * emulator (BE-14): what the parents' summary says, and who may end a shift
 * (nanny-hub ADR-0002).
 */

const at = (minute: number): Timestamp =>
  Timestamp.fromDate(new Date(Date.UTC(2026, 8, 29, 15, minute)));

function entry(overrides: Record<string, unknown> = {}): Record<string, unknown> {
  return {
    kind: 'meal',
    note: 'Ate all the pasta',
    mood: null,
    childIds: ['m-kid'],
    photoId: null,
    at: at(0),
    byMemberId: 'm-nomsa',
    createdAt: at(0),
    ...overrides,
  };
}

function reasonOf(action: () => unknown): unknown {
  try {
    action();
  } catch (error) {
    return error instanceof HttpsError ? (error.details as { reason: string }).reason : error;
  }
  return 'no refusal';
}

describe('a shift summary', () => {
  it('counts every kind of entry, including those it never saw', () => {
    const summary = summariseShift({
      entries: [entry(), entry({ kind: 'nap' }), entry({ kind: 'nap' })],
      ticks: {},
      checklists: {},
    });
    expect(summary.counts).toEqual({
      meal: 1,
      nap: 2,
      nappy: 0,
      mood: 0,
      incident: 0,
      medicine: 0,
      note: 0,
    });
    expect(summary.entryCount).toBe(3);
  });

  it('tells the evening in the order it happened, whatever order it was read in', () => {
    const summary = summariseShift({
      entries: [entry({ note: 'bath', at: at(40) }), entry({ note: 'tea', at: at(5) })],
      ticks: {},
      checklists: {},
    });
    expect(summary.moments.map((moment) => moment.note)).toEqual(['tea', 'bath']);
  });

  it('names every child the evening was about, once each', () => {
    const summary = summariseShift({
      entries: [entry({ childIds: ['m-zoe', 'm-kid'] }), entry({ childIds: ['m-kid'] })],
      ticks: {},
      checklists: {},
    });
    expect(summary.childIds).toEqual(['m-kid', 'm-zoe']);
  });

  it('says how many photos there were, without copying them', () => {
    const summary = summariseShift({
      entries: [entry({ photoId: 'photo-0001' }), entry()],
      ticks: {},
      checklists: {},
    });
    expect(summary.photoCount).toBe(1);
    expect(summary.moments.map((moment) => moment.hasPhoto)).toEqual([true, false]);
    expect(JSON.stringify(summary)).not.toContain('photo-0001');
  });

  it('keeps an unreadable entry out rather than failing the end of the shift', () => {
    const summary = summariseShift({
      entries: [entry(), { kind: 'fireworks', at: at(1) }, { kind: 'meal' }],
      ticks: {},
      checklists: {},
    });
    expect(summary.entryCount).toBe(1);
    expect(summary.unreadableCount).toBe(2);
  });

  it('repeats at most its limit of moments, and says when it trimmed', () => {
    const many = Array.from({ length: SUMMARY_MOMENT_LIMIT + 5 }, (_, index) =>
      entry({ at: at(index % 59) }),
    );
    const summary = summariseShift({ entries: many, ticks: {}, checklists: {} });
    expect(summary.moments).toHaveLength(SUMMARY_MOMENT_LIMIT);
    expect(summary.isTrimmed).toBe(true);
    expect(summary.counts.meal).toBe(SUMMARY_MOMENT_LIMIT + 5);
  });

  it('does not say it trimmed a short evening', () => {
    expect(summariseShift({ entries: [entry()], ticks: {}, checklists: {} }).isTrimmed).toBe(false);
  });
});

describe('checklist progress', () => {
  const checklists = {
    arrival: {
      items: [
        { id: 'bags', text: 'Unpack bags' },
        { id: 'snack', text: 'Snack' },
      ],
    },
    bedtime: { items: [{ id: 'teeth', text: 'Brush teeth' }] },
  };

  it('counts ticked items against every item that exists', () => {
    expect(checklistProgress({ 'arrival:bags': true, 'bedtime:teeth': true }, checklists)).toEqual({
      ticked: 2,
      total: 3,
    });
  });

  it('ignores a tick for an item a parent has since removed', () => {
    expect(checklistProgress({ 'arrival:gone': true }, checklists)).toEqual({
      ticked: 0,
      total: 3,
    });
  });

  it('ignores a tick in the wrong moment, and anything that is not true', () => {
    expect(checklistProgress({ 'bedtime:bags': true, 'arrival:snack': 'yes' }, checklists)).toEqual(
      { ticked: 0, total: 3 },
    );
  });

  it('reads no ticks at all as nothing done', () => {
    expect(checklistProgress(undefined, checklists).ticked).toBe(0);
    expect(checklistProgress(['arrival:bags'], checklists).ticked).toBe(0);
  });
});

describe('who may write the hub and end a shift', () => {
  const household = {
    members: { 'uid-sam': 'admin', 'uid-nomsa': 'carer', 'uid-vera': 'carer', 'uid-lee': 'member' },
    profiles: { 'uid-sam': 'm-sam', 'uid-nomsa': 'm-nomsa', 'uid-vera': 'm-vera' },
    access: {
      'uid-nomsa': ROLE_DEFAULTS.carer,
      'uid-vera': { ...ROLE_DEFAULTS.carer, nannyHub: 'view' },
    },
  };

  it('lets a carer on the carer defaults, whose hub is edit', () => {
    const caller = hubEditorFrom(household, 'uid-nomsa');
    expect(caller).toEqual({ uid: 'uid-nomsa', isFamily: false, memberId: 'm-nomsa' });
  });

  it('refuses a carer a parent gave the hub at view', () => {
    expect(reasonOf(() => hubEditorFrom(household, 'uid-vera'))).toBe('hubNotShared');
  });

  it('refuses somebody who is not in the household', () => {
    expect(reasonOf(() => hubEditorFrom(household, 'uid-stranger'))).toBe('notAMember');
    expect(reasonOf(() => hubEditorFrom({ name: 'no members' }, 'uid-sam'))).toBe('notAMember');
  });

  it('lets family in, including the old `member` with no profile entry', () => {
    expect(hubEditorFrom(household, 'uid-lee')).toEqual({
      uid: 'uid-lee',
      isFamily: true,
      memberId: null,
    });
  });

  it('lets a carer end only their own shift, and family end anybody’s', () => {
    const nomsa = hubEditorFrom(household, 'uid-nomsa');
    const sam = hubEditorFrom(household, 'uid-sam');
    expect(mayEndShift(nomsa, 'm-nomsa')).toBe(true);
    expect(mayEndShift(nomsa, 'm-vera')).toBe(false);
    expect(mayEndShift(sam, 'm-vera')).toBe(true);
  });
});

describe('the end-of-shift body', () => {
  const body = { householdId: 'h1', shiftId: 'shift-1', closingNote: null };

  it('treats a blank closing note as none, and trims one that is there', () => {
    expect(parseInput(endNannyShiftInput, { ...body, closingNote: '   ' }).closingNote).toBeNull();
    expect(
      parseInput(endNannyShiftInput, { ...body, closingNote: ' Asleep by 8 ' }).closingNote,
    ).toBe('Asleep by 8');
  });

  it('refuses a closing note longer than an entry’s', () => {
    expect(() => parseInput(endNannyShiftInput, { ...body, closingNote: 'x'.repeat(501) })).toThrow(
      HttpsError,
    );
  });

  it('every refusal carries a gRPC code the client can fall back on', () => {
    for (const [reason, [code]] of Object.entries(NANNY_REFUSALS)) {
      expect(code, reason).toMatch(/^[a-z-]+$/);
    }
  });
});
