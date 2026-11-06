import { Timestamp } from 'firebase-admin/firestore';
import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest';

import { assembleFrameDay } from '../../../src/frames/frame_day';
import { type FrameShareDocument, frameDocument } from '../../../src/frames/frame_documents';
import { refuseFrame } from '../../../src/frames/frame_errors';
import {
  FRAME_SHARE_FRESH_MS,
  FRAME_SHARE_PER_UID,
  FRAME_SHARE_WAIT_MS,
  FRAME_SHARE_WAIT_PER_CREDENTIAL,
} from '../../../src/frames/frame_policy';
import {
  claimFramePairingInput,
  sharePageInput,
  shareToFrameInput,
  waitFrameShareInput,
} from '../../../src/frames/frame_schemas';
import {
  type FrameShareSnapshot,
  type FrameShareSource,
  awaitFrameShare,
  shareQualifies,
  shared,
} from '../../../src/frames/frame_shares';
import { parseInput } from '../../../src/household/parse_input';

const NOW = new Date('2026-10-30T08:00:00Z');
const SECRET = 'a'.repeat(43);
const PANELS = {
  calendar: true,
  todos: false,
  meals: false,
  lunch: false,
  addEvents: false,
  share: true,
  people: false,
  helperMemberId: null,
};

function share(id: string, ageMs = 0): FrameShareDocument {
  return {
    id,
    url: 'https://example.com/recipe',
    title: 'Curry',
    by: 'Sam',
    at: Timestamp.fromMillis(NOW.getTime() - ageMs),
  };
}

function snapshot(data: Record<string, unknown> | undefined): FrameShareSnapshot {
  return { exists: data !== undefined, data: () => data };
}

function frameWith(stored: FrameShareDocument | null, panels = PANELS): Record<string, unknown> {
  return { name: 'Kitchen', panels, share: stored };
}

class FakeFrame implements FrameShareSource {
  onNext: ((snapshot: FrameShareSnapshot) => void) | undefined;
  onError: ((error: Error) => void) | undefined;
  listening = 0;

  constructor(private readonly first?: FrameShareSnapshot) {}

  onSnapshot(
    onNext: (snapshot: FrameShareSnapshot) => void,
    onError: (error: Error) => void,
  ): () => void {
    this.onNext = onNext;
    this.onError = onError;
    this.listening += 1;
    if (this.first !== undefined) onNext(this.first);
    return () => {
      this.listening -= 1;
    };
  }
}

describe('a share qualifies', () => {
  it('when it is not the one the frame last opened and is at most ten minutes old', () => {
    expect(shareQualifies(share('share-0001'), null, NOW)).toBe(true);
    expect(shareQualifies(share('share-0001'), 'share-0000', NOW)).toBe(true);
    expect(shareQualifies(share('share-0001', FRAME_SHARE_FRESH_MS), null, NOW)).toBe(true);
  });

  it('never when it is the same one, stale, or missing', () => {
    expect(shareQualifies(share('share-0001'), 'share-0001', NOW)).toBe(false);
    expect(shareQualifies(share('share-0001', FRAME_SHARE_FRESH_MS + 1), null, NOW)).toBe(false);
    expect(shareQualifies(null, null, NOW)).toBe(false);
  });
});

describe('waiting for a share', () => {
  beforeEach(() => {
    vi.useFakeTimers();
    vi.setSystemTime(NOW);
  });
  afterEach(() => {
    vi.useRealTimers();
  });

  it('answers with the first qualifying share and stops listening', async () => {
    const frame = new FakeFrame(snapshot(frameWith(share('share-0001'))));
    const waiting = awaitFrameShare(frame, 'share-0001', FRAME_SHARE_WAIT_MS);
    frame.onNext?.(snapshot(frameWith(share('share-0001'))));
    frame.onNext?.(snapshot(frameWith(share('share-0002'))));
    await expect(waiting).resolves.toEqual({
      id: 'share-0002',
      kind: 'page',
      url: 'https://example.com/recipe',
      title: 'Curry',
      by: 'Sam',
    });
    expect(frame.listening).toBe(0);
    expect(vi.getTimerCount()).toBe(0);
  });

  it('answers at once when the first snapshot already qualifies', async () => {
    const frame = new FakeFrame(snapshot(frameWith(share('share-0002'))));
    await expect(awaitFrameShare(frame, null, FRAME_SHARE_WAIT_MS)).resolves.toMatchObject({
      id: 'share-0002',
    });
    expect(frame.listening).toBe(0);
    expect(vi.getTimerCount()).toBe(0);
  });

  it('answers null at the deadline and stops listening', async () => {
    const frame = new FakeFrame(snapshot(frameWith(share('share-0001'))));
    const waiting = awaitFrameShare(frame, 'share-0001', FRAME_SHARE_WAIT_MS);
    await vi.advanceTimersByTimeAsync(FRAME_SHARE_WAIT_MS - 1);
    expect(frame.listening).toBe(1);
    await vi.advanceTimersByTimeAsync(1);
    await expect(waiting).resolves.toBeNull();
    expect(frame.listening).toBe(0);
  });

  it('ignores a stale share until the deadline', async () => {
    const frame = new FakeFrame(snapshot(frameWith(share('share-0002', FRAME_SHARE_FRESH_MS + 1))));
    const waiting = awaitFrameShare(frame, null, FRAME_SHARE_WAIT_MS);
    await vi.advanceTimersByTimeAsync(FRAME_SHARE_WAIT_MS);
    await expect(waiting).resolves.toBeNull();
    expect(frame.listening).toBe(0);
  });

  it('answers null when the frame is deleted meanwhile', async () => {
    const frame = new FakeFrame(snapshot(frameWith(null)));
    const waiting = awaitFrameShare(frame, null, FRAME_SHARE_WAIT_MS);
    frame.onNext?.(snapshot(undefined));
    await expect(waiting).resolves.toBeNull();
    expect(frame.listening).toBe(0);
    expect(vi.getTimerCount()).toBe(0);
  });

  it('answers null when sharing is switched off meanwhile, even with a new share', async () => {
    const frame = new FakeFrame(snapshot(frameWith(null)));
    const waiting = awaitFrameShare(frame, null, FRAME_SHARE_WAIT_MS);
    frame.onNext?.(snapshot(frameWith(share('share-0003'), { ...PANELS, share: false })));
    await expect(waiting).resolves.toBeNull();
    expect(frame.listening).toBe(0);
  });

  it('fails with the listener’s error and stops listening', async () => {
    const frame = new FakeFrame();
    const waiting = awaitFrameShare(frame, null, FRAME_SHARE_WAIT_MS);
    frame.onError?.(new Error('stream closed'));
    await expect(waiting).rejects.toThrow('stream closed');
    expect(frame.listening).toBe(0);
    expect(vi.getTimerCount()).toBe(0);
  });
});

describe('the stored frame', () => {
  it('has sharing off when the switch is missing or broken', () => {
    const older = { calendar: true, todos: true, meals: true, helperMemberId: null };
    expect(frameDocument.parse({ name: 'Kitchen', panels: older }).panels.share).toBe(false);
    expect(
      frameDocument.parse({ name: 'Kitchen', panels: { ...older, share: 'yes' } }).panels.share,
    ).toBe(false);
    expect(
      frameDocument.parse({ name: 'Kitchen', panels: { ...older, share: true } }).panels.share,
    ).toBe(true);
  });

  it('keeps a share it can read, and reads a broken one as none without unlinking', () => {
    expect(frameDocument.parse(frameWith(share('share-0001'))).share).toEqual(share('share-0001'));
    expect(frameDocument.parse({ name: 'Kitchen', panels: PANELS }).share).toBeNull();
    for (const broken of ['x', { id: 'share-0001' }, { ...share('share-0001'), at: 'now' }]) {
      const stored = frameDocument.parse({ name: 'Kitchen', panels: PANELS, share: broken });
      expect(stored.share).toBeNull();
      expect(stored.panels.share).toBe(true);
    }
  });

  it('is claimed with sharing off unless the app switches it on', () => {
    const claim = {
      householdId: 'h1',
      code: 'ABC234',
      name: 'Kitchen',
      panels: { calendar: true, todos: true, meals: true, helperMemberId: null },
    };
    expect(parseInput(claimFramePairingInput, claim).panels.share).toBe(false);
    expect(
      parseInput(claimFramePairingInput, { ...claim, panels: { ...claim.panels, share: true } })
        .panels.share,
    ).toBe(true);
  });
});

describe('the day tells a frame to wait for shares', () => {
  const sources = {
    householdName: 'The Parkers',
    frameName: 'Kitchen',
    panels: PANELS,
    screensaver: null,
    today: '2026-10-30',
    localMinute: 9 * 60,
    names: {},
    colors: {},
  };

  it('only while sharing is on', () => {
    expect(assembleFrameDay(sources).sharing).toBe(true);
    expect(
      assembleFrameDay({ ...sources, panels: { ...PANELS, share: false } }),
    ).not.toHaveProperty('sharing');
  });
});

describe('shareToFrame’s input', () => {
  const body = { householdId: 'h1', frameId: 'f1', url: 'https://example.com/' };

  it('takes a title trimmed, without control characters, at most 200, and empty as none', () => {
    expect(parseInput(sharePageInput, body).title).toBeNull();
    expect(parseInput(sharePageInput, { ...body, title: null }).title).toBeNull();
    expect(parseInput(sharePageInput, { ...body, title: '  \n\t ' }).title).toBeNull();
    expect(
      parseInput(sharePageInput, { ...body, title: ' Chicken\u0000 curry\u0007 ' }).title,
    ).toBe('Chicken curry');
    expect(parseInput(sharePageInput, { ...body, title: 'é'.repeat(250) }).title).toBe(
      'é'.repeat(200),
    );
  });

  it('refuses a url past 2048 and ids that are not ids', () => {
    expect(() =>
      parseInput(shareToFrameInput, { ...body, url: `https://example.com/${'a'.repeat(2030)}` }),
    ).toThrow();
    expect(() => parseInput(shareToFrameInput, { ...body, frameId: '' })).toThrow();
    expect(() => parseInput(shareToFrameInput, { ...body, householdId: 'x'.repeat(65) })).toThrow();
    expect(() => parseInput(shareToFrameInput, { ...body, url: 7 })).toThrow();
    expect(() => parseInput(sharePageInput, { ...body, title: 7 })).toThrow();
  });
});

describe('waitFrameShare’s input', () => {
  it('takes the share the frame last opened, or none', () => {
    expect(parseInput(waitFrameShareInput, { secret: SECRET }).after).toBeNull();
    expect(parseInput(waitFrameShareInput, { secret: SECRET, after: null }).after).toBeNull();
    expect(
      parseInput(waitFrameShareInput, { secret: SECRET, after: 'AbCdEfGhIj0123456789' }).after,
    ).toBe('AbCdEfGhIj0123456789');
    for (const after of ['short', 'a/b/c/d/e/f', 'x'.repeat(65), 7]) {
      expect(() => parseInput(waitFrameShareInput, { secret: SECRET, after })).toThrow();
    }
  });
});

describe('the share rules', () => {
  it('thirty shares per person per ten minutes, 150 waits per frame per hour', () => {
    expect(FRAME_SHARE_PER_UID).toEqual({
      name: 'shareToFrame:uid',
      limit: 30,
      windowSeconds: 600,
    });
    expect(FRAME_SHARE_WAIT_PER_CREDENTIAL).toEqual({
      name: 'waitFrameShare:credential',
      limit: 150,
      windowSeconds: 3600,
    });
    expect(FRAME_SHARE_FRESH_MS).toBe(600_000);
    expect(FRAME_SHARE_WAIT_MS).toBe(50_000);
  });

  it('refuse with their own reasons', () => {
    expect(refuseFrame('frameNotFound').code).toBe('not-found');
    expect(refuseFrame('sharingOff').code).toBe('failed-precondition');
    expect(refuseFrame('badLink').code).toBe('invalid-argument');
    expect(refuseFrame('badLink').details).toEqual({ reason: 'badLink' });
  });
});

describe('a recipe shared to the frame', () => {
  const recipe = {
    recipeId: 'bobotie',
    name: 'Bobotie',
    summary: 'Spiced mince under a golden custard.',
    people: 4,
    servings: 6,
    prepMinutes: 20,
    cookMinutes: 40,
    difficulty: 'easy' as const,
    photo: true,
    prepNote: null,
    ingredients: [{ group: null, amount: '665 g', name: 'Beef mince', note: null }],
    steps: [
      {
        text: 'Bake for 35–40 minutes.',
        timers: [{ start: 9, end: 22, seconds: 2100, upToSeconds: 2400 }],
      },
    ],
  };

  function recipeShare(id: string, ageMs = 0): FrameShareDocument {
    return {
      id,
      kind: 'recipe',
      title: 'Bobotie',
      by: 'Sam',
      at: Timestamp.fromMillis(NOW.getTime() - ageMs),
      recipe,
      photoPath: 'recipes/bobotie/hero-0123abcd.jpg',
    };
  }

  it('reaches only a frame that asks for recipes', () => {
    expect(shareQualifies(recipeShare('share-0001'), null, NOW)).toBe(false);
    expect(shareQualifies(recipeShare('share-0001'), null, NOW, ['page'])).toBe(false);
    expect(shareQualifies(recipeShare('share-0001'), null, NOW, ['page', 'recipe'])).toBe(true);
    expect(shareQualifies(share('share-0001'), null, NOW, ['recipe'])).toBe(false);
  });

  it('is answered with the recipe and never its storage path', () => {
    expect(shared(recipeShare('share-0001'))).toEqual({
      id: 'share-0001',
      kind: 'recipe',
      title: 'Bobotie',
      by: 'Sam',
      recipe,
    });
  });

  it('is skipped by a wait that does not accept it', async () => {
    vi.useFakeTimers();
    const frame = new FakeFrame(snapshot(frameWith(recipeShare('share-0002'))));
    const waiting = awaitFrameShare(frame, null, FRAME_SHARE_WAIT_MS);
    await vi.advanceTimersByTimeAsync(FRAME_SHARE_WAIT_MS);
    await expect(waiting).resolves.toBeNull();
    expect(frame.listening).toBe(0);
    vi.useRealTimers();
  });

  it('is stored and read back, and a share with an unknown kind reads as none', () => {
    expect(frameDocument.parse(frameWith(recipeShare('share-0001'))).share).toEqual(
      recipeShare('share-0001'),
    );
    const unknown = { ...share('share-0001'), kind: 'video' };
    expect(
      frameDocument.parse({ name: 'Kitchen', panels: PANELS, share: unknown }).share,
    ).toBeNull();
    const noRecipe = { ...recipeShare('share-0001'), recipe: { name: 'Bobotie' } };
    expect(
      frameDocument.parse({ name: 'Kitchen', panels: PANELS, share: noRecipe }).share,
    ).toBeNull();
  });

  it('reads a frame that never said what it opens as pages only', () => {
    expect(frameDocument.parse({ name: 'Kitchen', panels: PANELS }).accepts).toEqual(['page']);
    expect(frameDocument.parse({ name: 'Kitchen', panels: PANELS, accepts: 'x' }).accepts).toEqual([
      'page',
    ]);
    expect(
      frameDocument.parse({ name: 'Kitchen', panels: PANELS, accepts: ['page', 'recipe'] }).accepts,
    ).toEqual(['page', 'recipe']);
  });

  it('takes a recipe or a link, and a frame lists what it opens', () => {
    const recipeBody = {
      householdId: 'h1',
      frameId: 'f1',
      recipe: { id: 'bobotie', people: 4, amounts: ['665 g', null] },
    };
    expect(parseInput(shareToFrameInput, recipeBody)).toEqual(recipeBody);
    expect(() =>
      parseInput(shareToFrameInput, { ...recipeBody, recipe: { ...recipeBody.recipe, people: 0 } }),
    ).toThrow();
    expect(() => parseInput(shareToFrameInput, { householdId: 'h1', frameId: 'f1' })).toThrow();
    expect(parseInput(waitFrameShareInput, { secret: SECRET }).accepts).toEqual(['page']);
    expect(
      parseInput(waitFrameShareInput, { secret: SECRET, accepts: ['recipe', 'video', 'page'] })
        .accepts,
    ).toEqual(['page', 'recipe']);
    expect(parseInput(waitFrameShareInput, { secret: SECRET, accepts: [] }).accepts).toEqual([]);
  });

  it('names the new refusals', () => {
    for (const reason of ['frameCantOpen', 'recipeNotFound', 'badRecipe'] as const) {
      expect(refuseFrame(reason).details).toEqual({ reason });
    }
  });
});
