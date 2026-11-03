import { HttpsError } from 'firebase-functions/v2/https';
import { describe, expect, it } from 'vitest';

import { tickFrameItemInput } from '../../../src/frames/frame_schemas';
import { creditFor, inTickReach, nextTicks } from '../../../src/frames/frame_ticks';
import { parseInput } from '../../../src/household/parse_input';

/** A tick from the wall (photo-frames ADR-0007). */

const NAMES = { 'm-sam': 'Sam Parker', 'm-mia': 'Mia', 'm-mia2': 'Mia Jones', 'm-leo': 'Leo' };
const SECRET = 'a'.repeat(43);

describe('what a frame may tick', () => {
  it('today and the seven days behind it, nothing ahead', () => {
    expect(inTickReach('2026-10-25', '2026-10-25')).toBe(true);
    expect(inTickReach('2026-10-18', '2026-10-25')).toBe(true);
    expect(inTickReach('2026-10-17', '2026-10-25')).toBe(false);
    expect(inTickReach('2026-10-26', '2026-10-25')).toBe(false);
  });

  it('a task or a routine, with a real date and nothing else', () => {
    const body = { secret: SECRET, kind: 'task', id: 'dishes', date: '2026-10-25', done: true };
    expect(parseInput(tickFrameItemInput, body)).toEqual(body);
    for (const bad of [
      { ...body, kind: 'job' },
      { ...body, date: '2026-13-01' },
      { ...body, date: '25 Oct' },
      { ...body, id: '' },
      { ...body, done: 'yes' },
      { ...body, by: 'x'.repeat(61) },
    ]) {
      expect(() => parseInput(tickFrameItemInput, bad)).toThrow(HttpsError);
    }
  });
});

describe('who a tick credits', () => {
  it('the only person it is for, whatever the frame says', () => {
    expect(creditFor(['m-leo'], NAMES, null)).toBe('m-leo');
    expect(creditFor(['m-leo'], NAMES, 'Sam')).toBe('m-leo');
  });

  it('otherwise the one whose first name the frame sends, in any case', () => {
    expect(creditFor(['m-sam', 'm-leo'], NAMES, ' sam ')).toBe('m-sam');
    expect(creditFor(['m-sam', 'm-leo'], NAMES, null)).toBeNull();
    expect(creditFor(['m-sam', 'm-leo'], NAMES, 'Mia')).toBeNull();
  });

  it('nobody when two of them share the first name', () => {
    expect(creditFor(['m-mia', 'm-mia2'], NAMES, 'Mia')).toBeNull();
  });
});

describe('a routine’s steps after a tick', () => {
  const steps = ['basin', 'floor', 'mirror'];
  it('one step on or off, in the routine’s order, dropping steps it no longer has', () => {
    expect(nextTicks(steps, ['mirror', 'gone'], 'basin', true)).toEqual(['basin', 'mirror']);
    expect(nextTicks(steps, ['basin', 'mirror'], 'basin', false)).toEqual(['mirror']);
  });

  it('every step at once', () => {
    expect(nextTicks(steps, ['floor'], null, true)).toEqual(steps);
    expect(nextTicks(steps, steps, null, false)).toEqual([]);
  });
});
