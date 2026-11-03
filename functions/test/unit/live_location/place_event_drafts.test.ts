import { describe, expect, it } from 'vitest';

import {
  FLAP_WINDOW_MS,
  REPEAT_WINDOW_MS,
  isNews,
  placeEventDrafts,
} from '../../../src/live_location/place_event_delivery';
import { ROSTER } from '../notifications/fixtures';

describe('who hears that somebody reached a place', () => {
  const arrived = placeEventDrafts(
    ROSTER,
    { memberId: 'm-mia', eventId: 'e1' },
    { kind: 'arrive', placeName: 'School' },
    '2026-11-02',
  );

  it('is everybody who can see the map, never the person who moved', () => {
    expect(arrived.map((draft) => draft.memberId).sort()).toEqual(['m-pat', 'm-sam']);
  });

  it('names who and where on a parent’s lock screen (notifications ADR-0004)', () => {
    for (const draft of arrived) {
      expect(draft.detail).toBe('Mia arrived at School');
      expect(draft.text).toEqual({ title: 'Mia arrived', body: 'Mia arrived at School' });
    }
  });

  it('keeps the names off the lock screen of anybody who is not family', () => {
    const kidSees = placeEventDrafts(
      ROSTER,
      { memberId: 'm-sam', eventId: 'e3' },
      { kind: 'arrive', placeName: 'Home' },
      '2026-11-02',
    ).find((draft) => draft.memberId === 'm-mia');
    expect(kidSees?.detail).toBe('Sam arrived at Home');
    expect(`${kidSees?.text.title ?? ''} ${kidSees?.text.body ?? ''}`).not.toMatch(/Sam|Home/);
  });

  it('lands on the map, opened on the member, as a places notification', () => {
    expect(arrived[0]).toMatchObject({
      category: 'places',
      target: { kind: 'whereWeAre', id: 'm-mia' },
      source: { kind: 'placeEvent', id: 'e1' },
      id: `place_e1_${arrived[0]?.memberId ?? ''}`,
    });
  });

  it('says leaving as leaving', () => {
    const left = placeEventDrafts(
      ROSTER,
      { memberId: 'm-sam', eventId: 'e2' },
      { kind: 'leave', placeName: 'Home' },
      '2026-11-02',
    );
    expect(left.map((draft) => draft.detail)).toContain('Sam left Home');
    expect(left.map((draft) => draft.memberId)).not.toContain('m-sam');
  });
});

describe('whether a crossing is news', () => {
  const at = Date.UTC(2026, 10, 2, 7);

  it('is news the first time, and after a missed exit the next day', () => {
    expect(isNews(undefined, 'arrive', at)).toBe(true);
    expect(isNews({ kind: 'arrive', at }, 'arrive', at + 22 * 3600 * 1000)).toBe(true);
  });

  it('is not news when the same kind is told again inside half an hour', () => {
    expect(isNews({ kind: 'arrive', at }, 'arrive', at + REPEAT_WINDOW_MS - 1)).toBe(false);
  });

  it('is not news when the fence flaps inside two minutes', () => {
    expect(isNews({ kind: 'arrive', at }, 'leave', at + FLAP_WINDOW_MS - 1)).toBe(false);
    expect(isNews({ kind: 'arrive', at }, 'leave', at + FLAP_WINDOW_MS)).toBe(true);
  });

  it('reads the old one-word record as no record', () => {
    expect(isNews('arrive', 'arrive', at)).toBe(true);
  });
});
