import type { RateLimitRule } from '../shared/rate_limit';
import type { FramePanels } from './frame_schemas';

/**
 * The rules of photo frames (photo-frames ADR-0001), as values and pure
 * functions so they are tested where they live (`BE-14`).
 */

/** The same six readable characters a kid pairing uses, shown on the frame and in its QR. */
export const FRAME_CODE_LENGTH = 6;
export const FRAME_CODE_LIFETIME_MS = 10 * 60 * 1000;
export const FRAME_POLL_SECONDS = 4;

/** A kitchen, a hallway, a gran's flat, and room to spare. */
export const FRAME_LIMIT = 5;

/** How stale `lastSeenAt` may get before a read refreshes it — a write per quarter hour, not per read. */
export const LAST_SEEN_EVERY_MS = 15 * 60 * 1000;

export const FRAME_DAY_AHEAD = 2;

/** How far back a missed chore stays on the wall and may still be ticked: the app's `overdueWindowDays` (todos ADR-0001). */
export const FRAME_OVERDUE_DAYS = 7;

/** How many months either side of this one a frame may page to. */
export const FRAME_MONTH_REACH = 12;

/**
 * The callables a frame makes are reachable by a device with no Firebase SDK, so
 * they never enforce App Check whatever the global switch says (foundation
 * ADR-0016); the secret and the rate limits are their guard instead.
 */
export const FRAME_DEVICE_OPTIONS = { enforceAppCheck: false } as const;

export const FRAME_START_PER_ADDRESS: RateLimitRule = {
  name: 'startFramePairing:address',
  limit: 30,
  windowSeconds: 60 * 60,
};
export const FRAME_START_OVERALL: RateLimitRule = {
  name: 'startFramePairing:all',
  limit: 2000,
  windowSeconds: 60 * 60,
};
/** A poll every four seconds for ten minutes is 150; four frames behind one router still fit. */
export const FRAME_POLL_PER_ADDRESS: RateLimitRule = {
  name: 'pollFramePairing:address',
  limit: 600,
  windowSeconds: 10 * 60,
};
export const FRAME_CLAIM_PER_UID: RateLimitRule = {
  name: 'claimFramePairing:uid',
  limit: 20,
  windowSeconds: 10 * 60,
};
/** Sixty reads an hour at the daytime refresh, one every fifteen seconds while someone touches the frame, and retries. */
export const FRAME_DAY_PER_CREDENTIAL: RateLimitRule = {
  name: 'getFrameDay:credential',
  limit: 360,
  windowSeconds: 60 * 60,
};

/** A month only while someone pages through it on the wall, and the 15-minute refresh while it stays open. */
export const FRAME_MONTH_PER_CREDENTIAL: RateLimitRule = {
  name: 'getFrameMonth:credential',
  limit: 120,
  windowSeconds: 60 * 60,
};

/** The album's list on a screensaver's start, and its refresh while it runs. */
export const FRAME_PHOTOS_PER_CREDENTIAL: RateLimitRule = {
  name: 'getFramePhotos:credential',
  limit: 120,
  windowSeconds: 60 * 60,
};

/** One photo every ten seconds for an hour is 360; the rest is a retry. */
export const FRAME_PHOTO_PER_CREDENTIAL: RateLimitRule = {
  name: 'getFramePhoto:credential',
  limit: 600,
  windowSeconds: 60 * 60,
};

/** A few boxes a day, fetched once each, and their retries (photo-frames ADR-0009). */
export const FRAME_LUNCH_PHOTO_PER_CREDENTIAL: RateLimitRule = {
  name: 'getFrameLunchPhoto:credential',
  limit: 60,
  windowSeconds: 60 * 60,
};

/** The newest photos a screensaver cycles through (photo-frames ADR-0006). */
export const FRAME_PHOTO_LIMIT = 100;

/** How many of the album's objects a list reads before it picks the newest. */
export const FRAME_PHOTO_SCAN = 1000;

export const SCREENSAVER_IDLE_MINUTES = [0, 1, 2, 5, 10, 15, 30, 60] as const;
export const SCREENSAVER_SECONDS_PER_PHOTO = [10, 20, 30, 60] as const;

/** A family ticking through the day at the wall, and undoing a few (photo-frames ADR-0007). */
export const FRAME_TICK_PER_CREDENTIAL: RateLimitRule = {
  name: 'tickFrameItem:credential',
  limit: 240,
  windowSeconds: 60 * 60,
};

/** A family adding the week's plans at the wall, with room for a few mistakes (photo-frames ADR-0008). */
export const FRAME_ADD_EVENT_PER_CREDENTIAL: RateLimitRule = {
  name: 'addFrameEvent:credential',
  limit: 60,
  windowSeconds: 60 * 60,
};

/** How far ahead a frame may add an event. */
export const FRAME_EVENT_REACH_MONTHS = 12;

/** A frame adds events only while it shows the calendar and family switched adding on (ADR-0008). */
export function addsEvents(panels: FramePanels): boolean {
  return panels.calendar && panels.addEvents;
}

/** The shops a frame may add groceries from (photo-frames ADR-0012), by the app's `ProductRetailer.code`. */
export const FRAME_GROCERY_SHOPS = ['checkers', 'pickNPay', 'woolworths'] as const;
export type FrameGroceryShop = (typeof FRAME_GROCERY_SHOPS)[number];

/** The price fields a Woolworths store's price list reads, as the phone resolved it for the frame. */
export const WOOLWORTHS_PRICE_ZONES = ['p10', 'p30', 'p60'] as const;

/** Someone typing an item a letter at a time, debounced, for a long shopping list (ADR-0012). */
export const FRAME_SEARCH_PRODUCTS_PER_CREDENTIAL: RateLimitRule = {
  name: 'searchFrameProducts:credential',
  limit: 300,
  windowSeconds: 60 * 60,
};

/** A family adding the week's shopping at the wall (ADR-0012). */
export const FRAME_ADD_GROCERY_PER_CREDENTIAL: RateLimitRule = {
  name: 'addFrameGroceryItem:credential',
  limit: 60,
  windowSeconds: 60 * 60,
};

/** A grocery name is also its normalised key, which the grocery rules cap at 80; the app's bound on a quantity. */
export const GROCERY_NAME_LIMIT = 80;
export const GROCERY_QUANTITY_LIMIT = 40;

/** As many items as the app's own list reads (the day's `toBuy` comes from them). */
export const FRAME_GROCERY_READ_LIMIT = 200;

/** Unbought items read to find the same name; more than any list holds. */
export const FRAME_UNBOUGHT_READ_LIMIT = 500;

/** Products a frame search answers with. */
export const FRAME_PRODUCT_LIMIT = 5;

/** Jev's score the first product needs to be called the best: the app's `bestMatchFit`. */
export const FRAME_BEST_MATCH_FIT = 0.6;

/** A frame unlinks once; the rest is a retry on a bad connection. */
export const FRAME_UNLINK_PER_CREDENTIAL: RateLimitRule = {
  name: 'unlinkFrame:credential',
  limit: 10,
  windowSeconds: 60 * 60,
};

export const FRAME_SHARE_PER_UID: RateLimitRule = {
  name: 'shareToFrame:uid',
  limit: 30,
  windowSeconds: 10 * 60,
};

export const FRAME_SHARE_WAIT_PER_CREDENTIAL: RateLimitRule = {
  name: 'waitFrameShare:credential',
  limit: 150,
  windowSeconds: 60 * 60,
};

export const FRAME_RECIPE_PHOTO_PER_CREDENTIAL: RateLimitRule = {
  name: 'getFrameRecipePhoto:credential',
  limit: 60,
  windowSeconds: 60 * 60,
};

export const FRAME_SHARE_FRESH_MS = 10 * 60 * 1000;
export const FRAME_SHARE_WAIT_MS = 50 * 1000;

const DAY_STARTS = 6 * 60;
const DAY_ENDS = 22 * 60;
const MIDNIGHT = 24 * 60;

/** A minute while the household is up, half an hour while it sleeps, and never past midnight so the wall turns the page. */
export function refreshAfterSeconds(localMinute: number): number {
  const every = localMinute >= DAY_STARTS && localMinute < DAY_ENDS ? 60 : 1800;
  return Math.min(every, (MIDNIGHT - localMinute) * 60);
}

export function lastSeenIsStale(lastSeenAt: Date | null, now: Date): boolean {
  return lastSeenAt === null || now.getTime() - lastSeenAt.getTime() >= LAST_SEEN_EVERY_MS;
}
