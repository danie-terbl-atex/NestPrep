import { describe, expect, it } from 'vitest';

import { ACCESSORIES, MOMENTS, NESTLINGS } from '../../../src/avatars/avatar_catalogue';
import {
  type AvatarOwned,
  NO_OWNED,
  adultStage,
  choiceOfLook,
  isValidChoice,
  lookOf,
  parseChoice,
  parseLook,
  parseOwned,
  sameLook,
  sanitized,
} from '../../../src/avatars/avatar_look';
import { decidePurchase } from '../../../src/avatars/avatar_purchase';
import { starStage } from '../../../src/avatars/avatar_stage';

/** A member's choice and the look mirrored from it (avatars ADR-0001, ADR-0004). */

const HASH = '0123456789abcdef0123456789abcdef';
const OWNS: AvatarOwned = { accessories: ['acc-crown'], images: [HASH] };

describe('the catalogue the server checks against', () => {
  it('names every asset the way the frame and the app look them up', () => {
    for (const nestling of NESTLINGS) expect(nestling.name).toMatch(/^[a-z0-9-]{1,40}$/);
    for (const accessory of ACCESSORIES) expect(accessory.id).toMatch(/^acc-[a-z0-9-]{1,44}$/);
    for (const moment of MOMENTS) expect(moment.id).toMatch(/^moment-[a-z0-9-]{1,41}$/);
  });

  it('has the free and priced accessories the seed and the tests lean on', () => {
    expect(ACCESSORIES.find((a) => a.id === 'acc-crown')).toMatchObject({ slot: 'top', stars: 20 });
    expect(ACCESSORIES.find((a) => a.id === 'acc-round-glasses')).toMatchObject({
      slot: 'face',
      stars: 0,
    });
    expect(NESTLINGS.map((n) => n.name)).toEqual(expect.arrayContaining(['pip', 'olive']));
  });
});

describe('reading what is stored', () => {
  it('reads a choice, and refuses one with a stray key or a stage out of range', () => {
    expect(parseChoice({ base: 'preset:pip', wear: { top: 'acc-crown' } })).toEqual({
      base: 'preset:pip',
      wear: { top: 'acc-crown' },
    });
    expect(parseChoice({ base: 'initial', stage: 2, wear: {} })).toEqual({
      base: 'initial',
      stage: 2,
      wear: {},
    });
    expect(parseChoice({ base: 'initial', wear: {}, extra: 1 })).toBeUndefined();
    expect(parseChoice({ base: 'initial', stage: 4, wear: {} })).toBeUndefined();
    expect(parseChoice({ base: 'initial', wear: { hat: 'acc-crown' } })).toBeUndefined();
    expect(parseChoice(undefined)).toBeUndefined();
  });

  it('reads what is owned, and nothing for anything else', () => {
    expect(parseOwned({ accessories: ['acc-crown'], images: [HASH] })).toEqual(OWNS);
    expect(parseOwned({ accessories: 'acc-crown' })).toEqual(NO_OWNED);
    expect(parseOwned(undefined)).toEqual(NO_OWNED);
  });

  it('reads a look, and nothing for one of another version', () => {
    const look = { v: 1, base: 'preset:pip', stage: 2, wear: { top: 'acc-crown' } };
    expect(parseLook(look)).toEqual(look);
    expect(parseLook({ ...look, v: 2 })).toBeUndefined();
    expect(parseLook({ ...look, stage: 7 })).toBeUndefined();
  });
});

describe('whether a choice may stand', () => {
  it('takes the initial, a Nestling in the catalogue and an owned picture', () => {
    expect(isValidChoice({ base: 'initial', wear: {} }, NO_OWNED)).toBe(true);
    expect(isValidChoice({ base: 'preset:pip', wear: {} }, NO_OWNED)).toBe(true);
    expect(isValidChoice({ base: `image:${HASH}`, wear: {} }, OWNS)).toBe(true);
  });

  it('refuses an unknown Nestling, a picture not owned and a base of another kind', () => {
    expect(isValidChoice({ base: 'preset:godzilla', wear: {} }, OWNS)).toBe(false);
    expect(isValidChoice({ base: `image:${HASH}`, wear: {} }, NO_OWNED)).toBe(false);
    expect(isValidChoice({ base: 'image:nothex', wear: {} }, OWNS)).toBe(false);
    expect(isValidChoice({ base: 'emoji:cat', wear: {} }, OWNS)).toBe(false);
  });

  it('wears what is free, and what is priced only once it is owned', () => {
    expect(isValidChoice({ base: 'initial', wear: { top: 'acc-cap' } }, NO_OWNED)).toBe(true);
    expect(isValidChoice({ base: 'initial', wear: { top: 'acc-crown' } }, NO_OWNED)).toBe(false);
    expect(isValidChoice({ base: 'initial', wear: { top: 'acc-crown' } }, OWNS)).toBe(true);
  });

  it('lets anyone who is not a kid wear any accessory unowned, still only where it fits', () => {
    const crown = { base: 'initial', wear: { top: 'acc-crown' } };
    expect(isValidChoice(crown, NO_OWNED, true)).toBe(true);
    expect(isValidChoice(crown, NO_OWNED, false)).toBe(false);
    expect(isValidChoice({ base: 'initial', wear: { badge: 'acc-crown' } }, NO_OWNED, true)).toBe(
      false,
    );
    expect(isValidChoice({ base: 'initial', wear: { top: 'acc-jetpack' } }, NO_OWNED, true)).toBe(
      false,
    );
    expect(isValidChoice({ base: 'initial', wear: { face: 'acc-monocle' } }, NO_OWNED, true)).toBe(
      false,
    );
  });

  it('refuses an accessory in the wrong slot or not in the catalogue', () => {
    expect(isValidChoice({ base: 'initial', wear: { badge: 'acc-cap' } }, OWNS)).toBe(false);
    expect(isValidChoice({ base: 'initial', wear: { top: 'acc-jetpack' } }, OWNS)).toBe(false);
    expect(isValidChoice({ base: 'initial', wear: { top: 'moment-birthday-hat' } }, OWNS)).toBe(
      false,
    );
  });

  it('puts something on the face only of a Nestling', () => {
    const glasses = { face: 'acc-round-glasses' };
    expect(isValidChoice({ base: 'preset:pip', wear: glasses }, NO_OWNED)).toBe(true);
    expect(isValidChoice({ base: 'initial', wear: glasses }, NO_OWNED)).toBe(false);
    expect(isValidChoice({ base: `image:${HASH}`, wear: glasses }, OWNS)).toBe(false);
  });
});

describe('taking a bad choice back to a good one', () => {
  it('takes off what may not be worn and makes an unknown base the initial', () => {
    expect(
      sanitized(
        { base: 'preset:godzilla', wear: { top: 'acc-crown', face: 'acc-round-glasses' } },
        OWNS,
      ),
    ).toEqual({ base: 'initial', wear: { top: 'acc-crown' } });
  });

  it('reads the last valid choice back from the look, with a stage only for an adult', () => {
    const look = {
      v: 1 as const,
      base: 'preset:pip',
      stage: 2 as const,
      wear: { top: 'acc-crown' },
    };
    expect(choiceOfLook(look, false, OWNS)).toEqual({
      base: 'preset:pip',
      stage: 2,
      wear: { top: 'acc-crown' },
    });
    expect(choiceOfLook(look, true, OWNS)).toEqual({
      base: 'preset:pip',
      wear: { top: 'acc-crown' },
    });
    expect(choiceOfLook({ ...look, base: null }, true, OWNS)).toEqual({
      base: 'initial',
      wear: { top: 'acc-crown' },
    });
  });

  it('keeps a grown-up’s unowned accessory, and takes it off a kid', () => {
    const look = {
      v: 1 as const,
      base: 'preset:pip',
      stage: 3 as const,
      wear: { top: 'acc-halo' },
    };
    expect(choiceOfLook(look, false, NO_OWNED).wear).toEqual({ top: 'acc-halo' });
    expect(choiceOfLook(look, true, NO_OWNED).wear).toEqual({});
    expect(
      sanitized({ base: 'preset:pip', wear: { top: 'acc-halo' } }, NO_OWNED, true).wear,
    ).toEqual({ top: 'acc-halo' });
  });

  it('is the initial when there was never a look, and never a choice that is itself bad', () => {
    expect(choiceOfLook(undefined, true, NO_OWNED)).toEqual({ base: 'initial', wear: {} });
    const stale = {
      v: 1 as const,
      base: 'preset:retired',
      stage: 1 as const,
      wear: { top: 'acc-old' },
    };
    const back = choiceOfLook(stale, true, NO_OWNED);
    expect(isValidChoice(back, NO_OWNED)).toBe(true);
  });
});

describe('the look mirrored from a choice', () => {
  it('is version 1, the base or null for the initial, a stage and what is worn', () => {
    expect(lookOf({ base: 'preset:pip', wear: { top: 'acc-crown' } }, 1)).toEqual({
      v: 1,
      base: 'preset:pip',
      stage: 1,
      wear: { top: 'acc-crown' },
    });
    expect(lookOf({ base: 'initial', wear: {} }, 3)).toEqual({
      v: 1,
      base: null,
      stage: 3,
      wear: {},
    });
  });

  it('gives an adult the stage they chose, or a grown bird', () => {
    expect(adultStage({ base: 'preset:pip', stage: 1, wear: {} })).toBe(1);
    expect(adultStage({ base: 'preset:pip', wear: {} })).toBe(3);
  });

  it('is the same look whatever order its wear was written in', () => {
    const a = lookOf({ base: 'preset:pip', wear: { top: 'acc-cap', badge: 'acc-star' } }, 2);
    const b = lookOf({ base: 'preset:pip', wear: { badge: 'acc-star', top: 'acc-cap' } }, 2);
    expect(sameLook(a, b)).toBe(true);
    expect(sameLook(a, { ...b, stage: 3 })).toBe(false);
    expect(sameLook(undefined, b)).toBe(false);
  });
});

describe('a kid’s stage from their stars', () => {
  it.each([
    [{ earned: 0, bestStreak: 0 }, 0],
    [{ earned: 1, bestStreak: 0 }, 1],
    [{ earned: 40, bestStreak: 2 }, 1],
    [{ earned: 5, bestStreak: 3 }, 2],
    [{ earned: 5, bestStreak: 6 }, 2],
    [{ earned: 5, bestStreak: 7 }, 3],
    [{ earned: 5, bestStreak: 30 }, 3],
  ])('%o is stage %i', (stars, stage) => {
    expect(starStage(stars)).toBe(stage);
  });

  it('never goes back to an egg when every star is unticked again', () => {
    expect(starStage({ earned: 0, bestStreak: 1 })).toBe(1);
  });
});

describe('whether an accessory can be bought', () => {
  const crown = ACCESSORIES.find((a) => a.id === 'acc-crown');
  const cap = ACCESSORIES.find((a) => a.id === 'acc-cap');
  const facts = {
    accessory: crown,
    shopOn: true,
    memberRole: 'kid',
    owned: NO_OWNED,
    balance: 20,
  };

  it('buys it when a kid has the stars and the shop is open', () => {
    expect(decidePurchase(facts)).toBe('buy');
  });

  it('says why not, in this order', () => {
    expect(decidePurchase({ ...facts, accessory: undefined, shopOn: false })).toBe(
      'unknownAccessory',
    );
    expect(decidePurchase({ ...facts, shopOn: false, memberRole: 'parent' })).toBe('shopOff');
    expect(decidePurchase({ ...facts, memberRole: 'parent' })).toBe('notAKid');
    expect(decidePurchase({ ...facts, memberRole: undefined })).toBe('notAKid');
    expect(decidePurchase({ ...facts, owned: OWNS, balance: 0 })).toBe('alreadyOwned');
    expect(decidePurchase({ ...facts, balance: 19 })).toBe('notEnoughStars');
  });

  it('never sells what is free: everybody has it already', () => {
    expect(decidePurchase({ ...facts, accessory: cap })).toBe('alreadyOwned');
  });
});
