import { z } from 'zod';

import { dayNumber } from '../../documents/expiry_schedule';

/**
 * The shapes an assistant's arguments must have before anything is read or
 * written (assistants ADR-0001). The rules check little inside an event or a
 * grocery item, and the Admin SDK skips them anyway, so these hold every
 * written value to what the app writes and reads: days as `YYYY-MM-DD`,
 * times as the household's wall clock, a recurrence the app can expand.
 */

/** Longest event title the server keeps — the calendar import's own bound. */
export const TITLE_LIMIT = 200;
export const NOTE_LIMIT = 1000;

/** A grocery name is also its normalised key, which the rules cap at 80. */
export const GROCERY_NAME_LIMIT = 80;
export const GROCERY_QUANTITY_LIMIT = 40;

/** Items one call may add, tick or remove. */
export const GROCERY_BATCH_LIMIT = 50;

/** Members one event may name. */
export const MEMBER_IDS_LIMIT = 20;

/** The widest window `list_events` expands, in days, both ends included. */
export const EVENT_WINDOW_DAYS = 62;

const DOCUMENT_ID = /^[A-Za-z0-9_-]{1,128}$/;

export const documentId = z.string().regex(DOCUMENT_ID, 'not a NestPrep id');

export const calendarDate = z
  .string()
  .regex(/^\d{4}-\d{2}-\d{2}$/, 'a day as YYYY-MM-DD')
  .refine((value) => dayNumber(value) !== undefined, 'not a day in the calendar');

export const wallClockTime = z
  .string()
  .regex(/^([01]\d|2[0-3]):[0-5]\d$/, 'a 24-hour time as HH:MM')
  .describe('24-hour wall-clock time where the household lives, HH:MM');

export const memberIds = z
  .array(documentId)
  .max(MEMBER_IDS_LIMIT)
  .describe('Member ids from get_household. Empty means the whole household.');

export const eventTitle = z.string().trim().min(1).max(TITLE_LIMIT);
export const eventNote = z.string().trim().max(NOTE_LIMIT);
export const groceryName = z.string().trim().min(1).max(GROCERY_NAME_LIMIT);
export const groceryQuantity = z
  .string()
  .trim()
  .max(GROCERY_QUANTITY_LIMIT)
  .describe('Free text, as a person writes it: "2 kg", "a few", "6".');

/**
 * A repeat rule, held to the Dart `RecurrenceRule.isExpandable`: an interval
 * from 1 to 366, ISO weekdays (Monday 1, Sunday 7) on a weekly rule only, and
 * an end no earlier than the first day (checked against it by the tool).
 */
export const recurrenceInput = z
  .strictObject({
    frequency: z.enum(['daily', 'weekly', 'monthly']),
    interval: z
      .number()
      .int()
      .min(1)
      .max(366)
      .default(1)
      .describe('Every nth day, week or month; 1 means every one.'),
    weekdays: z
      .array(z.number().int().min(1).max(7))
      .max(7)
      .default([])
      .describe(
        'Weekly only: ISO weekdays, Monday 1 to Sunday 7. Empty means the weekday of the first day.',
      ),
    until: calendarDate.nullable().default(null).describe('Last day it may happen, YYYY-MM-DD.'),
  })
  .refine((rule) => rule.frequency === 'weekly' || rule.weekdays.length === 0, {
    message: 'weekdays belong to a weekly rule only',
    path: ['weekdays'],
  })
  .refine((rule) => new Set(rule.weekdays).size === rule.weekdays.length, {
    message: 'a weekday is named once',
    path: ['weekdays'],
  });
export type RecurrenceInput = z.output<typeof recurrenceInput>;

/** Minutes since midnight of an `HH:MM`. */
export function minuteOf(time: string): number {
  const [hours = '0', minutes = '0'] = time.split(':');
  return Number(hours) * 60 + Number(minutes);
}

/** `HH:MM` of minutes since midnight. */
export function timeOf(minute: number): string {
  const hours = Math.floor(minute / 60);
  return `${String(hours).padStart(2, '0')}:${String(minute % 60).padStart(2, '0')}`;
}
