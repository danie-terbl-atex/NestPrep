import { addDays, daysInMonth, isoDate, weekdayOf } from './zoned_time';

/**
 * The RFC 5545 repeat rules a family calendar actually uses, and nothing more
 * (calendar ADR-0003): `DAILY`, `WEEKLY` on plain weekdays, `MONTHLY` on the
 * start's day or on one "nth weekday", `YEARLY` on the start's date, each with
 * `INTERVAL`, `COUNT` and `UNTIL`. A rule outside that is reported as
 * unsupported, and its event is imported once rather than guessed at.
 */
export interface IcsRule {
  readonly frequency: 'DAILY' | 'WEEKLY' | 'MONTHLY' | 'YEARLY';
  readonly interval: number;
  readonly count: number | null;
  /** `YYYYMMDD` or `YYYYMMDDTHHMMSS[Z]`, as written. */
  readonly until: string | null;
  /** ISO weekdays, for `WEEKLY`. */
  readonly weekdays: readonly number[];
  /** "the 2nd Tuesday": for `MONTHLY`; `-1` is the last. */
  readonly nthWeekday: { readonly nth: number; readonly weekday: number } | null;
}

const WEEKDAY_CODES: Readonly<Record<string, number>> = {
  MO: 1,
  TU: 2,
  WE: 3,
  TH: 4,
  FR: 5,
  SA: 6,
  SU: 7,
};

const IGNORABLE = new Set(['WKST']);

/** The rule in [value] for an event starting on [startDate], or null if unsupported. */
export function parseRule(value: string, startDate: string): IcsRule | null {
  const parts: Record<string, string> = {};
  for (const piece of value.split(';')) {
    const [key = '', part = ''] = piece.split('=');
    if (key !== '') parts[key.toUpperCase()] = part.toUpperCase();
  }
  const frequency = parts['FREQ'];
  if (
    frequency !== 'DAILY' &&
    frequency !== 'WEEKLY' &&
    frequency !== 'MONTHLY' &&
    frequency !== 'YEARLY'
  ) {
    return null;
  }
  const interval = Number(parts['INTERVAL'] ?? '1');
  const count = parts['COUNT'] === undefined ? null : Number(parts['COUNT']);
  if (!Number.isInteger(interval) || interval < 1) return null;
  if (count !== null && (!Number.isInteger(count) || count < 1)) return null;

  const byDay = parts['BYDAY'];
  const [, startMonth = '', startDay = ''] = startDate.split('-');
  for (const key of Object.keys(parts)) {
    if (['FREQ', 'INTERVAL', 'COUNT', 'UNTIL', 'BYDAY'].includes(key) || IGNORABLE.has(key)) {
      continue;
    }
    // A BYMONTHDAY or BYMONTH that only restates the start adds nothing.
    if (key === 'BYMONTHDAY' && Number(parts[key]) === Number(startDay)) continue;
    if (key === 'BYMONTH' && Number(parts[key]) === Number(startMonth)) continue;
    return null;
  }

  let weekdays: number[] = [];
  let nthWeekday: IcsRule['nthWeekday'] = null;
  if (byDay !== undefined) {
    if (frequency === 'WEEKLY') {
      const days = byDay.split(',').map((code) => WEEKDAY_CODES[code]);
      if (days.some((day) => day === undefined)) return null;
      weekdays = [...new Set(days.filter((day): day is number => day !== undefined))].sort();
    } else if (frequency === 'MONTHLY') {
      const match = /^([+-]?\d)(MO|TU|WE|TH|FR|SA|SU)$/.exec(byDay);
      const nth = Number(match?.[1]);
      const weekday = WEEKDAY_CODES[match?.[2] ?? ''];
      if (match === null || weekday === undefined || nth === 0 || nth > 5 || nth < -1) return null;
      nthWeekday = { nth, weekday };
    } else {
      return null;
    }
  }
  return { frequency, interval, count, until: parts['UNTIL'] ?? null, weekdays, nthWeekday };
}

/**
 * The days [rule] lands on from [startDate], ascending, stopping after
 * [lastDate] or once `COUNT` is spent. [skipBefore] lets a rule with no count
 * jump over years of history instead of walking them (FE-12's server twin);
 * a counted rule has to walk from the start, and its count bounds the walk.
 */
export function ruleDates(
  rule: IcsRule,
  startDate: string,
  lastDate: string,
  skipBefore: string,
): string[] {
  const dates: string[] = [];
  const limit = rule.count ?? Number.POSITIVE_INFINITY;
  const push = (date: string): boolean => {
    if (date < startDate) return true;
    if (date > lastDate || dates.length >= limit) return false;
    dates.push(date);
    return true;
  };
  const from = rule.count === null && skipBefore > startDate ? skipBefore : startDate;
  switch (rule.frequency) {
    case 'DAILY':
      daily(rule, startDate, from, push);
      break;
    case 'WEEKLY':
      weekly(rule, startDate, from, push);
      break;
    case 'MONTHLY':
    case 'YEARLY':
      monthly(rule, startDate, lastDate, push);
      break;
  }
  return dates;
}

type Push = (date: string) => boolean;

/** Steps the loops will take at most — a guard, never the expected stop. */
const MAX_STEPS = 5_000;

function daily(rule: IcsRule, startDate: string, from: string, push: Push): void {
  const elapsed = Math.max(0, Math.round((Date.parse(from) - Date.parse(startDate)) / 86_400_000));
  let step = Math.floor(elapsed / rule.interval);
  for (let guard = 0; guard < MAX_STEPS; guard++, step++) {
    if (!push(addDays(startDate, step * rule.interval))) return;
  }
}

function weekly(rule: IcsRule, startDate: string, from: string, push: Push): void {
  const weekdays = rule.weekdays.length > 0 ? rule.weekdays : [weekdayOf(startDate)];
  const firstWeek = addDays(startDate, 1 - weekdayOf(startDate));
  const elapsedWeeks = Math.max(
    0,
    Math.floor((Date.parse(from) - Date.parse(firstWeek)) / (7 * 86_400_000)),
  );
  let week = Math.floor(elapsedWeeks / rule.interval);
  for (let guard = 0; guard < MAX_STEPS; guard++, week++) {
    const monday = addDays(firstWeek, week * rule.interval * 7);
    for (const weekday of weekdays) {
      if (!push(addDays(monday, weekday - 1))) return;
    }
  }
}

function monthly(rule: IcsRule, startDate: string, lastDate: string, push: Push): void {
  const [year = 0, month = 1, day = 1] = startDate.split('-').map(Number);
  const stepMonths = rule.frequency === 'YEARLY' ? 12 * rule.interval : rule.interval;
  for (let guard = 0; guard < MAX_STEPS; guard++) {
    const total = year * 12 + (month - 1) + guard * stepMonths;
    const targetYear = Math.floor(total / 12);
    const targetMonth = (total % 12) + 1;
    const date = dayInMonth(rule, targetYear, targetMonth, day);
    // A month with no such day is skipped, as RFC 5545 and foundation
    // ADR-0005 both say: the 31st never becomes the 30th.
    if (date === null) {
      if (isoDate(targetYear, targetMonth, 1) > lastDate) return;
      continue;
    }
    if (!push(date)) return;
  }
}

function dayInMonth(rule: IcsRule, year: number, month: number, day: number): string | null {
  const nth = rule.nthWeekday;
  if (nth === null) return day > daysInMonth(year, month) ? null : isoDate(year, month, day);
  const first = isoDate(year, month, 1);
  const offset = (nth.weekday - weekdayOf(first) + 7) % 7;
  if (nth.nth === -1) {
    const last = isoDate(year, month, daysInMonth(year, month));
    return addDays(last, -((weekdayOf(last) - nth.weekday + 7) % 7));
  }
  const date = 1 + offset + (nth.nth - 1) * 7;
  return date > daysInMonth(year, month) ? null : isoDate(year, month, date);
}
