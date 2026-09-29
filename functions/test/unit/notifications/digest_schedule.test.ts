import { describe, expect, it } from 'vitest';

import {
  candidateSlots,
  dueDigestDay,
  knownZones,
  slotOf,
} from '../../../src/notifications/digest_schedule';
import { readSettings } from '../../../src/notifications/notification_settings';

/**
 * When a digest is due (notifications ADR-0002): the household's own clock,
 * a household far from the launch market, the two clock changes, and a run
 * that is late or never came.
 */

const at = (iso: string): Date => new Date(iso);

function wanting(minute: number, enabled = true): ReturnType<typeof readSettings> {
  return readSettings({ digest: { enabled, minute } });
}

const HALF_SIX = 6 * 60 + 30;

describe('the household’s own morning', () => {
  it('is 06:30 in Johannesburg at 04:30 UTC', () => {
    expect(dueDigestDay(wanting(HALF_SIX), 'Africa/Johannesburg', at('2026-09-29T04:30:00Z'))).toBe(
      '2026-09-29',
    );
  });

  it('is not due an hour early or an hour late', () => {
    const settings = wanting(HALF_SIX);
    expect(
      dueDigestDay(settings, 'Africa/Johannesburg', at('2026-09-29T03:30:00Z')),
    ).toBeUndefined();
    expect(
      dueDigestDay(settings, 'Africa/Johannesburg', at('2026-09-29T05:30:00Z')),
    ).toBeUndefined();
  });

  it('comes at a household’s own morning on the far side of the world, on its own date', () => {
    // 06:30 on the 30th in Auckland is 17:30 on the 29th in UTC.
    expect(dueDigestDay(wanting(HALF_SIX), 'Pacific/Auckland', at('2026-09-29T17:30:00Z'))).toBe(
      '2026-09-30',
    );
    expect(
      dueDigestDay(wanting(HALF_SIX), 'Africa/Johannesburg', at('2026-09-29T17:30:00Z')),
    ).toBeUndefined();
  });

  it('a person who changes the time gets it then', () => {
    const later = wanting(8 * 60);
    expect(dueDigestDay(later, 'Africa/Johannesburg', at('2026-09-29T04:30:00Z'))).toBeUndefined();
    expect(dueDigestDay(later, 'Africa/Johannesburg', at('2026-09-29T06:00:00Z'))).toBe(
      '2026-09-29',
    );
  });

  it('a person who opted out never gets it', () => {
    expect(
      dueDigestDay(wanting(HALF_SIX, false), 'Africa/Johannesburg', at('2026-09-29T04:30:00Z')),
    ).toBeUndefined();
  });
});

describe('a run that is late, or never came', () => {
  it('a run three minutes late still finds the slot', () => {
    expect(dueDigestDay(wanting(HALF_SIX), 'Africa/Johannesburg', at('2026-09-29T04:33:00Z'))).toBe(
      '2026-09-29',
    );
  });

  it('the next run catches up a slot that had no run at all', () => {
    expect(dueDigestDay(wanting(HALF_SIX), 'Africa/Johannesburg', at('2026-09-29T04:45:00Z'))).toBe(
      '2026-09-29',
    );
  });

  it('but not two slots back', () => {
    expect(
      dueDigestDay(wanting(HALF_SIX), 'Africa/Johannesburg', at('2026-09-29T05:00:00Z')),
    ).toBeUndefined();
  });
});

describe('the clocks change', () => {
  it('on the morning London springs forward, 06:30 is 05:30 UTC', () => {
    // 29 March 2026: BST from 01:00 UTC.
    expect(dueDigestDay(wanting(HALF_SIX), 'Europe/London', at('2026-03-29T05:30:00Z'))).toBe(
      '2026-03-29',
    );
    expect(
      dueDigestDay(wanting(HALF_SIX), 'Europe/London', at('2026-03-29T06:30:00Z')),
    ).toBeUndefined();
  });

  it('the week before, the same 06:30 was 06:30 UTC', () => {
    expect(dueDigestDay(wanting(HALF_SIX), 'Europe/London', at('2026-03-22T06:30:00Z'))).toBe(
      '2026-03-22',
    );
  });

  it('on the morning London falls back, 06:30 is 06:30 UTC again', () => {
    // 25 October 2026: GMT from 01:00 UTC.
    expect(dueDigestDay(wanting(HALF_SIX), 'Europe/London', at('2026-10-25T06:30:00Z'))).toBe(
      '2026-10-25',
    );
  });

  it('an hour the clocks repeat is due twice, on the same day — which the inbox id makes once', () => {
    const settings = wanting(60 + 15);
    const first = dueDigestDay(settings, 'Europe/London', at('2026-10-25T00:15:00Z'));
    const second = dueDigestDay(settings, 'Europe/London', at('2026-10-25T01:15:00Z'));
    expect(first).toBe('2026-10-25');
    expect(second).toBe(first);
  });

  it('an hour the clocks skip is not due that day', () => {
    const settings = wanting(60 + 15);
    const runs = ['2026-03-29T00:15:00Z', '2026-03-29T00:30:00Z', '2026-03-29T01:15:00Z'];
    expect(runs.map((run) => dueDigestDay(settings, 'Europe/London', at(run)))).toEqual([
      undefined,
      undefined,
      undefined,
    ]);
  });
});

describe('which slots the job asks for', () => {
  it('asks only for slots that are now — or were a step ago — somewhere', () => {
    const slots = candidateSlots(at('2026-09-29T04:30:00Z'), ['Africa/Johannesburg', 'UTC']);
    expect(slots).toEqual([
      slotOf(4 * 60 + 15),
      slotOf(4 * 60 + 30),
      slotOf(6 * 60 + 15),
      slotOf(HALF_SIX),
    ]);
  });

  it('across every zone is a few dozen slots, never all ninety-six', () => {
    const slots = candidateSlots(at('2026-09-29T04:30:00Z'), knownZones());
    expect(slots.length).toBeGreaterThan(20);
    expect(slots.length).toBeLessThan(96);
    expect(slots).toContain(slotOf(HALF_SIX));
  });
});

describe('a stored time that is not on the quarter hour', () => {
  it('is read on the quarter hour it falls in', () => {
    expect(readSettings({ digest: { enabled: true, minute: 6 * 60 + 40 } }).digestMinute).toBe(
      HALF_SIX,
    );
  });
});
