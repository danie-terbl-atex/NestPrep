/**
 * What every part of the cloud demo seed shares: the household, the clock the
 * household reads, and a writer. Dates are always relative to the Monday of
 * the week the seed runs in, on the household's clock, so a reseed next month
 * looks as lived-in as the first one did.
 *
 * Johannesburg keeps +02:00 all year (no daylight saving), so a local time is
 * an instant with that offset — no timezone library needed.
 */
import { createRequire } from 'node:module';

const require = createRequire(import.meta.url);
const { Timestamp } = require('firebase-admin/firestore');

const OFFSET = '+02:00';
const DAY_MS = 86_400_000;

/** `YYYY-MM-DD` of [instant] on Johannesburg's clock. */
function localDay(instant) {
  return new Date(instant.getTime() + 2 * 3_600_000).toISOString().slice(0, 10);
}

/** [day] moved by [offset] days. */
export function addDays(day, offset) {
  return new Date(Date.parse(`${day}T00:00:00Z`) + offset * DAY_MS).toISOString().slice(0, 10);
}

/** ISO weekday of [day]: Monday is 1, Sunday is 7. */
export function weekdayOf(day) {
  const weekday = new Date(`${day}T00:00:00Z`).getUTCDay();
  return weekday === 0 ? 7 : weekday;
}

/** The ISO week `YYYY-Www` holding [day] — the lunch box's week key. */
export function isoWeekOf(day) {
  const thursday = addDays(day, 4 - weekdayOf(day));
  const year = Number(thursday.slice(0, 4));
  const firstThursday = addDays(`${String(year)}-01-04`, 4 - weekdayOf(`${String(year)}-01-04`));
  const week = 1 + Math.round((Date.parse(thursday) - Date.parse(firstThursday)) / (7 * DAY_MS));
  return `${String(year)}-W${String(week).padStart(2, '0')}`;
}

/** Minutes since midnight from `HH:mm`, the way the app stores a time of day. */
export function minuteOf(time) {
  const [hours, minutes] = time.split(':').map(Number);
  return hours * 60 + minutes;
}

export function createContext({ store, bucket, cast, now = new Date() }) {
  const today = localDay(now);
  const monday = addDays(today, 1 - weekdayOf(today));
  const household = store.collection('households').doc(cast.householdId);
  return {
    store,
    bucket,
    cast,
    now,
    household,
    today,
    /** Monday of this week. */
    monday,
    /** The day [offset] days from this Monday: 0 is Monday, 7 next Monday, -7 last. */
    day: (offset) => addDays(monday, offset),
    /** The instant of `HH:mm` on [day], on the household's clock. */
    at: (day, time = '08:00') => Timestamp.fromDate(new Date(`${day}T${time}:00${OFFSET}`)),
    /** An instant [hours] before now — for "a little while ago". */
    ago: (hours) => Timestamp.fromMillis(now.getTime() - hours * 3_600_000),
    col: (name) => household.collection(name),
  };
}

/** Writes [docs] ([ref, data] pairs) in bulk and waits for all of them. */
export async function writeAll(store, docs) {
  const writer = store.bulkWriter();
  const writes = docs.map(([ref, data]) => writer.set(ref, data));
  await writer.close();
  // A write that failed after its retries rejects here, never silently (ENG-10).
  await Promise.all(writes);
  return docs.length;
}
