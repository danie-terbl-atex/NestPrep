import { z } from 'zod';

import { daysInMonth } from '../calendar_sync/zoned_time';
import { NOTE_MAX } from './frame_day';
import { FRAME_SHARE_KINDS, type FrameShareKind } from './frame_documents';
import { FRAME_LINK_MAX } from './frame_links';
import { frameRecipeShareInput } from './frame_recipe';
import { GROCERY_NAME_LIMIT, GROCERY_QUANTITY_LIMIT } from './frame_policy';
import {
  FRAME_DEVICE_STATES,
  FRAME_UPDATE_APPS,
  FRAME_UPDATE_EVENT_KINDS,
  FRAME_UPDATE_LIST_LIMIT,
} from './frame_update_policy';

/**
 * Every photo frame callable's input, parsed at the edge and never cast
 * (`ENG-09`, `BE-03`). A frame sends its own secret and a code; which
 * household it belongs to is only ever read from the server's records.
 */

const id = z.string().trim().min(1).max(64);

/** Base64url of the 32 random bytes the frame made itself, with room for a longer one. */
const secret = z.string().regex(/^[A-Za-z0-9_-]{32,128}$/);

const code = z
  .string()
  .trim()
  .min(4)
  .max(16)
  .transform((value) => value.toUpperCase());

export const framePanels = z.object({
  calendar: z.boolean(),
  todos: z.boolean(),
  meals: z.boolean(),
  /** Missing on a frame linked by an older app: off. */
  lunch: z.boolean().default(false),
  /** Missing on a frame linked by an older app: off. */
  addEvents: z.boolean().default(false),
  share: z.boolean().default(false),
  people: z.boolean().default(false),
  helperMemberId: id.nullable(),
});
export type FramePanels = z.infer<typeof framePanels>;

export const startFramePairingInput = z.object({
  secret,
  model: z.string().trim().max(60).nullable().optional(),
});
export type StartFramePairingInput = z.infer<typeof startFramePairingInput>;

export const pollFramePairingInput = z.object({ code, secret });
export type PollFramePairingInput = z.infer<typeof pollFramePairingInput>;

export const claimFramePairingInput = z.object({
  householdId: id,
  code,
  name: z.string().trim().min(1).max(40),
  panels: framePanels,
});
export type ClaimFramePairingInput = z.infer<typeof claimFramePairingInput>;

export const getFrameDayInput = z.object({ secret });
export type GetFrameDayInput = z.infer<typeof getFrameDayInput>;

export const getFrameMonthInput = z.object({
  secret,
  month: z.string().regex(/^\d{4}-(0[1-9]|1[0-2])$/),
});
export type GetFrameMonthInput = z.infer<typeof getFrameMonthInput>;

export const getFramePhotosInput = z.object({ secret });
export type GetFramePhotosInput = z.infer<typeof getFramePhotosInput>;

/** An album photo's name, the same rule Storage holds an upload to. */
export const FRAME_PHOTO_ID = /^[A-Za-z0-9_-]{8,64}$/;

export const getFramePhotoInput = z.object({ secret, id: z.string().regex(FRAME_PHOTO_ID) });
export type GetFramePhotoInput = z.infer<typeof getFramePhotoInput>;

export const tickFrameItemInput = z.object({
  secret,
  kind: z.enum(['task', 'routine']),
  id,
  date: z.string().regex(/^\d{4}-(0[1-9]|1[0-2])-(0[1-9]|[12]\d|3[01])$/),
  done: z.boolean(),
  /** A first name as the day prints it; needed only when more than one person could have done it. */
  by: z.string().trim().min(1).max(60).nullable().optional(),
  /** One routine step; absent ticks or unticks every step. */
  step: id.nullable().optional(),
});
export type TickFrameItemInput = z.infer<typeof tickFrameItemInput>;

const name = z.string().trim().min(1).max(60);

const clock = z
  .string()
  .regex(/^([01]\d|2[0-3]):[0-5]\d$/)
  .transform((value) => Number(value.slice(0, 2)) * 60 + Number(value.slice(3)));

const orNull = <T>(value: T | null | undefined): T | null => value ?? null;

export const addFrameEventInput = z
  .object({
    secret,
    title: z.string().trim().min(1).max(120),
    date: z.string().refine(isCalendarDate),
    /** No start is all-day; an end before the start runs past midnight. */
    start: clock.nullish().transform(orNull),
    end: clock.nullish().transform(orNull),
    /** First names as the day prints them; none is everyone. */
    who: z.array(name).max(20),
    by: name,
    note: z
      .string()
      .trim()
      .max(NOTE_MAX)
      .nullish()
      .transform((note) => (note === '' || note === undefined ? null : note)),
    repeat: z.literal('weekly').nullish().transform(orNull),
    /** The same on a retry, so a frame that timed out never adds the event twice. */
    requestId: z
      .string()
      .regex(/^[A-Za-z0-9_-]{8,64}$/)
      .nullish()
      .transform(orNull),
  })
  .refine((input) => input.start !== null || input.end === null);
export type AddFrameEventInput = z.infer<typeof addFrameEventInput>;

export const FRAME_SHARE_TITLE_MAX = 200;
export const FRAME_SHARE_ID = /^[A-Za-z0-9_-]{8,64}$/;

export const sharePageInput = z.object({
  householdId: id,
  frameId: id,
  url: z.string().max(FRAME_LINK_MAX),
  title: z.string().nullish().transform(shareTitle),
});

export const shareRecipeInput = z.object({
  householdId: id,
  frameId: id,
  recipe: frameRecipeShareInput,
});

export const shareToFrameInput = z.union([shareRecipeInput, sharePageInput]);
export type ShareToFrameInput = z.infer<typeof shareToFrameInput>;

export const waitFrameShareInput = z.object({
  secret,
  after: z.string().regex(FRAME_SHARE_ID).nullish().transform(orNull),
  accepts: z
    .array(z.string().max(32))
    .max(16)
    .nullish()
    .transform((kinds): FrameShareKind[] =>
      kinds == null ? ['page'] : FRAME_SHARE_KINDS.filter((kind) => kinds.includes(kind)),
    ),
});
export type WaitFrameShareInput = z.infer<typeof waitFrameShareInput>;

export const searchFrameProductsInput = z.object({
  secret,
  query: z.string().trim().min(2).max(GROCERY_NAME_LIMIT),
});
export type SearchFrameProductsInput = z.infer<typeof searchFrameProductsInput>;

const productText = z.string().trim().min(1).max(200);
const brand = z
  .string()
  .trim()
  .max(100)
  .nullish()
  .transform((value) => (value === '' || value === undefined ? null : value));
const unitOfMeasure = z.string().regex(/^[A-Z0-9]{1,8}$/);
const priceCents = z.number().int().min(0).max(100_000_000);

/** A pick as `groceriesIsProductMatch` holds it, less who picked it and when. */
export const frameProductPick = z.discriminatedUnion('retailer', [
  z.object({
    retailer: z.literal('checkers'),
    productId: z.string().regex(/^[0-9a-f]{24}$/),
    articleCode: z.string().regex(/^[0-9A-Za-z]{1,40}$/),
    unitOfMeasure,
    name: productText,
    brand,
    priceCents,
    imageId: z.string().min(1).max(100).nullish().transform(orNull),
  }),
  z.object({
    retailer: z.literal('pickNPay'),
    productId: z.string().regex(/^[0-9]{6,20}_[A-Z]{2,3}$/),
    articleCode: z.string().regex(/^[0-9]{1,20}$/),
    unitOfMeasure,
    name: productText,
    brand,
    priceCents,
    imageId: z.string().min(1).max(300).nullish().transform(orNull),
  }),
  z
    .object({
      retailer: z.literal('woolworths'),
      productId: z.string().regex(/^[0-9]{6,14}$/),
      articleCode: z.string(),
      unitOfMeasure: z.enum(['EA', 'KG']),
      name: productText,
      brand,
      priceCents,
      imageId: z
        .string()
        .regex(/^[^/\s]{1,600}$/)
        .nullish()
        .transform(orNull),
    })
    .refine((pick) => pick.articleCode === pick.productId, { path: ['articleCode'] }),
]);
export type FrameProductPick = z.infer<typeof frameProductPick>;

export const addFrameGroceryItemInput = z.object({
  secret,
  name: z.string().trim().min(1).max(GROCERY_NAME_LIMIT),
  quantity: z
    .string()
    .trim()
    .max(GROCERY_QUANTITY_LIMIT)
    .nullish()
    .transform((value) => (value === '' || value === undefined ? null : value)),
  by: name,
  product: frameProductPick.nullish().transform(orNull),
  requestId: z
    .string()
    .regex(/^[A-Za-z0-9_-]{8,64}$/)
    .nullish()
    .transform(orNull),
});
export type AddFrameGroceryItemInput = z.infer<typeof addFrameGroceryItemInput>;

export const unlinkFrameInput = z.object({ secret });
export type UnlinkFrameInput = z.infer<typeof unlinkFrameInput>;

const versionCode = z.number().int().positive().max(2_100_000_000);
const installedVersion = z.object({ versionCode, versionName: z.string().max(40) });
const installedApps = z.object({ home: installedVersion.nullable(), agent: installedVersion });
const badVersions = z.array(versionCode).max(FRAME_UPDATE_LIST_LIMIT);
const deviceState = z.enum(FRAME_DEVICE_STATES);
const LAST_TIMESTAMP_MS = 253_402_300_799_999;

export const checkFrameUpdateInput = z.object({
  device: secret,
  frame: secret.nullish().transform(orNull).catch(null),
  model: z.string().trim().max(80),
  sdk: z.number().int().min(21).max(99),
  apps: installedApps,
  bad: z.object({ home: badVersions, agent: badVersions }),
  state: deviceState,
});
export type CheckFrameUpdateInput = z.infer<typeof checkFrameUpdateInput>;

export const getFrameUpdateApkInput = z.object({
  device: secret,
  app: z.enum(FRAME_UPDATE_APPS),
  versionCode,
});
export type GetFrameUpdateApkInput = z.infer<typeof getFrameUpdateApkInput>;

export const frameUpdateEvent = z.object({
  id: z.string().regex(/^[A-Za-z0-9_-]{8,40}$/),
  kind: z.enum(FRAME_UPDATE_EVENT_KINDS),
  app: z.enum(FRAME_UPDATE_APPS),
  versionCode,
  fromVersionCode: versionCode.nullish().transform(orNull),
  detail: z.string().max(200).nullish().transform(orNull),
  at: z.number().int().min(0).max(LAST_TIMESTAMP_MS),
});
export type FrameUpdateEvent = z.infer<typeof frameUpdateEvent>;

export const reportFrameUpdateInput = z.object({
  device: secret,
  apps: installedApps,
  state: deviceState,
  events: z.array(frameUpdateEvent).min(1).max(FRAME_UPDATE_LIST_LIMIT),
});
export type ReportFrameUpdateInput = z.infer<typeof reportFrameUpdateInput>;

function shareTitle(title: string | null | undefined): string | null {
  const cleaned = Array.from((title ?? '').replace(/\p{Cc}/gu, '').trim())
    .slice(0, FRAME_SHARE_TITLE_MAX)
    .join('')
    .trimEnd();
  return cleaned === '' ? null : cleaned;
}

function isCalendarDate(value: string): boolean {
  const match = /^(\d{4})-(\d{2})-(\d{2})$/.exec(value);
  if (match === null) return false;
  const [year, month, day] = match.slice(1).map(Number) as [number, number, number];
  return month >= 1 && month <= 12 && day >= 1 && day <= daysInMonth(year, month);
}
