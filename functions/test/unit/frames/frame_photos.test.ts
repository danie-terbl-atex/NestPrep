import { HttpsError } from 'firebase-functions/v2/https';
import { describe, expect, it } from 'vitest';

import { assembleFrameDay } from '../../../src/frames/frame_day';
import { frameDocument, framePhotosPrefix } from '../../../src/frames/frame_documents';
import { framePhotosOf } from '../../../src/frames/frame_photos';
import {
  FRAME_PHOTO_LIMIT,
  FRAME_LUNCH_PHOTO_PER_CREDENTIAL,
  FRAME_PHOTO_PER_CREDENTIAL,
  FRAME_PHOTOS_PER_CREDENTIAL,
} from '../../../src/frames/frame_policy';
import { getFramePhotoInput, getFramePhotosInput } from '../../../src/frames/frame_schemas';
import { parseInput } from '../../../src/household/parse_input';
import type { StoredObject } from '../../../src/shared/storage';

/** A frame's screensaver: its settings, its album and what a frame is told (photo-frames ADR-0006). */

const SECRET = 'a'.repeat(43);
const PREFIX = framePhotosPrefix('h1');
const PANELS = { calendar: false, todos: false, meals: false, helperMemberId: null };

function photo(id: string, createdAt: string, overrides: Partial<StoredObject> = {}): StoredObject {
  return {
    name: `${PREFIX}${id}`,
    size: 1000,
    timeCreated: new Date(createdAt),
    contentType: 'image/jpeg',
    ...overrides,
  };
}

function screensaverOf(screensaver: unknown): unknown {
  return frameDocument.parse({ name: 'Kitchen', panels: PANELS, lastSeenAt: null, screensaver })
    .screensaver;
}

describe('the album a screensaver cycles through', () => {
  it('is newest first, by id and size alone', () => {
    expect(
      framePhotosOf(
        [
          photo('beach-0001', '2026-10-01T08:00:00Z', { size: 2048 }),
          photo('party-0002', '2026-10-03T08:00:00Z'),
          photo('garden-003', '2026-10-02T08:00:00Z'),
        ],
        PREFIX,
      ),
    ).toEqual([
      { id: 'party-0002', bytes: 1000 },
      { id: 'garden-003', bytes: 1000 },
      { id: 'beach-0001', bytes: 2048 },
    ]);
  });

  it('leaves out what the app would not have put there', () => {
    expect(
      framePhotosOf(
        [
          photo('short', '2026-10-01T08:00:00Z'),
          photo('has a space', '2026-10-01T08:00:00Z'),
          photo('x'.repeat(65), '2026-10-01T08:00:00Z'),
          photo('nested/photo-01', '2026-10-01T08:00:00Z'),
          photo('a-png-0001', '2026-10-01T08:00:00Z', { contentType: 'image/png' }),
          photo('untyped-01', '2026-10-01T08:00:00Z', { contentType: null }),
          { ...photo('elsewhere-1', '2026-10-01T08:00:00Z'), name: 'households/h2/framePhotos/x' },
          photo('kept-00001', '2026-10-01T08:00:00Z'),
        ],
        PREFIX,
      ),
    ).toEqual([{ id: 'kept-00001', bytes: 1000 }]);
  });

  it('keeps at most the newest hundred, an undated photo last', () => {
    const many = Array.from({ length: FRAME_PHOTO_LIMIT + 5 }, (_, index) =>
      photo(
        `photo-${String(index).padStart(4, '0')}`,
        new Date(Date.UTC(2026, 0, 1, 0, index)).toISOString(),
      ),
    );
    const undated = { ...photo('undated-01', '2026-01-01T00:00:00Z'), timeCreated: null };
    const kept = framePhotosOf([undated, ...many], PREFIX);
    expect(kept).toHaveLength(FRAME_PHOTO_LIMIT);
    expect(kept[0]?.id).toBe(`photo-${String(FRAME_PHOTO_LIMIT + 4).padStart(4, '0')}`);
    expect(kept.map((found) => found.id)).not.toContain('undated-01');
    expect(
      framePhotosOf([undated, many[0] as StoredObject], PREFIX).map((found) => found.id),
    ).toEqual(['photo-0000', 'undated-01']);
  });
});

describe('a frame’s screensaver as stored', () => {
  it('is off when it was never set', () => {
    expect(
      frameDocument.parse({ name: 'Kitchen', panels: PANELS, lastSeenAt: null }).screensaver,
    ).toBeNull();
  });

  it('is off at zero minutes', () => {
    expect(screensaverOf({ idleMinutes: 0, secondsPerPhoto: 20 })).toBeNull();
  });

  it('is on at one of the choices', () => {
    expect(screensaverOf({ idleMinutes: 5, secondsPerPhoto: 30 })).toEqual({
      idleMinutes: 5,
      secondsPerPhoto: 30,
    });
    expect(screensaverOf({ idleMinutes: 60, secondsPerPhoto: 10, extra: true })).toEqual({
      idleMinutes: 60,
      secondsPerPhoto: 10,
    });
  });

  it.each([
    ['minutes off the list', { idleMinutes: 3, secondsPerPhoto: 20 }],
    ['seconds off the list', { idleMinutes: 5, secondsPerPhoto: 15 }],
    ['minutes as text', { idleMinutes: '5', secondsPerPhoto: 20 }],
    ['a half', { idleMinutes: 5 }],
    ['not a map', 'on'],
    ['null', null],
  ])('is off, and the frame still linked, with %s', (_, junk) => {
    const stored = frameDocument.parse({
      name: 'Kitchen',
      panels: PANELS,
      lastSeenAt: null,
      screensaver: junk,
    });
    expect(stored.screensaver).toBeNull();
    expect(stored.name).toBe('Kitchen');
  });
});

describe('the day tells a frame its screensaver', () => {
  const sources = {
    householdName: 'The Parkers',
    frameName: 'Kitchen',
    panels: { ...PANELS, lunch: false, addEvents: false, share: false },
    today: '2026-09-29',
    localMinute: 9 * 60,
    names: {},
    colors: {},
  };

  it('when it is on', () => {
    const day = assembleFrameDay({
      ...sources,
      screensaver: { idleMinutes: 10, secondsPerPhoto: 20 },
    });
    expect(day.screensaver).toEqual({ idleMinutes: 10, secondsPerPhoto: 20 });
  });

  it('and says nothing at all when it is off', () => {
    expect(assembleFrameDay({ ...sources, screensaver: null })).not.toHaveProperty('screensaver');
  });
});

describe('the photo endpoints’ edge and limits', () => {
  it('getFramePhotos takes the secret alone', () => {
    expect(parseInput(getFramePhotosInput, { secret: SECRET })).toEqual({ secret: SECRET });
    expect(() => parseInput(getFramePhotosInput, { secret: 'short' })).toThrow(HttpsError);
  });

  it('getFramePhoto takes the secret and a photo id the rules allow', () => {
    expect(getFramePhotoInput.safeParse({ secret: SECRET, id: 'beach-0001' }).success).toBe(true);
    for (const id of ['short', 'x'.repeat(65), '../other-household', 'has space1', 7]) {
      expect(getFramePhotoInput.safeParse({ secret: SECRET, id }).success, String(id)).toBe(false);
    }
    expect(getFramePhotoInput.safeParse({ id: 'beach-0001' }).success).toBe(false);
  });

  it('are limited per frame by the hour', () => {
    expect(FRAME_PHOTOS_PER_CREDENTIAL).toEqual({
      name: 'getFramePhotos:credential',
      limit: 120,
      windowSeconds: 3600,
    });
    expect(FRAME_PHOTO_PER_CREDENTIAL).toEqual({
      name: 'getFramePhoto:credential',
      limit: 600,
      windowSeconds: 3600,
    });
    expect(FRAME_LUNCH_PHOTO_PER_CREDENTIAL).toEqual({
      name: 'getFrameLunchPhoto:credential',
      limit: 60,
      windowSeconds: 3600,
    });
  });
});
