import { describe, expect, it } from 'vitest';

import { IMAGE_GAP_MS, IMAGE_WAIT_MAX_MS, imageTurnAfter } from '../../../src/avatars/image_pacing';

describe('an image turn', () => {
  const now = 1_000_000;

  it('is now when nobody has drawn for a minute', () => {
    expect(imageTurnAfter(0, now)).toBe(now);
    expect(imageTurnAfter(now - 1, now)).toBe(now);
  });

  it('waits for the minute already reserved', () => {
    expect(imageTurnAfter(now + IMAGE_GAP_MS, now)).toBe(now + IMAGE_GAP_MS);
    expect(imageTurnAfter(now + IMAGE_WAIT_MAX_MS, now)).toBe(now + IMAGE_WAIT_MAX_MS);
  });

  it('is refused when the queue is longer than a trigger can wait', () => {
    expect(imageTurnAfter(now + IMAGE_WAIT_MAX_MS + 1, now)).toBeNull();
  });
});
