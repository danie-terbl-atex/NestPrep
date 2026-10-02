import { Timestamp } from 'firebase-admin/firestore';
import { describe, expect, it } from 'vitest';

import { PENDING_FOR_MS, photoStateOf } from '../../../src/lunch_photos/photo_documents';

/** What a cached picture's document means when a phone asks (lunch-box ADR-0015). */

const NOW = new Date('2026-10-02T08:00:00Z');
const ago = (ms: number): Timestamp => Timestamp.fromMillis(NOW.getTime() - ms);

describe('a cached picture', () => {
  it('that is ready is handed back, with its path', () => {
    expect(photoStateOf({ status: 'ready', path: 'lunchPhotos/k.jpg' }, NOW)).toEqual({
      status: 'ready',
      path: 'lunchPhotos/k.jpg',
    });
  });

  it('being made by somebody else is waited for', () => {
    expect(photoStateOf({ status: 'pending', pendingSince: ago(5_000) }, NOW)).toEqual({
      status: 'pending',
    });
  });

  it('abandoned past the window is made again', () => {
    const stale = { status: 'pending', pendingSince: ago(PENDING_FOR_MS) };
    expect(photoStateOf(stale, NOW)).toEqual({ status: 'claimed' });
  });

  it.each([
    ['nothing', undefined],
    ['ready with no path', { status: 'ready' }],
    ['pending with no time', { status: 'pending' }],
    ['something else', { status: 'odd' }],
  ])('that is %s is made', (_label, stored) => {
    expect(photoStateOf(stored, NOW)).toEqual({ status: 'claimed' });
  });
});
