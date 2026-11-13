import { addDays } from '../calendar_sync/zoned_time';
import { MOMENTS, type AvatarSlot, type MomentRule } from './avatar_catalogue';
import { AVATAR_SLOTS, type AvatarWear } from './avatar_look';

/**
 * Moments — a birthday hat, the seasons, the days a family marks — are never
 * stored (avatars ADR-0001): they come from the household's date, its zone
 * and a member's birthday. The app computes the same from the same catalogue.
 */

export type Hemisphere = 'south' | 'north';

export interface MomentDay {
  /** `YYYY-MM-DD` in the household's zone. */
  readonly today: string;
  readonly hemisphere: Hemisphere;
  /** `YYYY-MM-DD` or `--MM-DD`, as the member stores it. */
  readonly birthday?: string | null | undefined;
}

export interface AvatarLayer {
  readonly slot: AvatarSlot;
  readonly id: string;
}

const SOUTHERN_ZONES = new Set([
  'Africa/Johannesburg',
  'Africa/Maseru',
  'Africa/Mbabane',
  'Africa/Windhoek',
  'Africa/Gaborone',
  'Africa/Harare',
  'Africa/Lusaka',
  'Africa/Maputo',
  'Africa/Blantyre',
  'Africa/Lubumbashi',
  'Africa/Luanda',
  'Africa/Dar_es_Salaam',
  'Africa/Kigali',
  'Africa/Bujumbura',
  'Indian/Antananarivo',
  'Indian/Mauritius',
  'Indian/Reunion',
  'Indian/Mayotte',
  'Indian/Comoro',
  'Pacific/Auckland',
  'Pacific/Chatham',
  'Pacific/Fiji',
  'Pacific/Tongatapu',
  'Pacific/Apia',
  'Pacific/Noumea',
  'Pacific/Port_Moresby',
  'Pacific/Tahiti',
  'America/Sao_Paulo',
  'America/Santiago',
  'America/Montevideo',
  'America/Asuncion',
  'America/La_Paz',
  'America/Lima',
  'Asia/Jakarta',
  'Atlantic/St_Helena',
]);

const SOUTHERN_PREFIXES = ['Australia/', 'America/Argentina/', 'Antarctica/'];

export function hemisphereOf(zone: string | null | undefined): Hemisphere {
  if (zone === null || zone === undefined) return 'north';
  return SOUTHERN_ZONES.has(zone) || SOUTHERN_PREFIXES.some((prefix) => zone.startsWith(prefix))
    ? 'south'
    : 'north';
}

/** Western Easter Sunday, `YYYY-MM-DD` (the anonymous Gregorian computus). */
export function easterSunday(year: number): string {
  const a = year % 19;
  const b = Math.floor(year / 100);
  const c = year % 100;
  const d = Math.floor(b / 4);
  const e = b % 4;
  const f = Math.floor((b + 8) / 25);
  const g = Math.floor((b - f + 1) / 3);
  const h = (19 * a + b - d - g + 15) % 30;
  const i = Math.floor(c / 4);
  const k = c % 4;
  const l = (32 + 2 * e + 2 * i - h - k) % 7;
  const m = Math.floor((a + 11 * h + 22 * l) / 451);
  const month = Math.floor((h + l - 7 * m + 114) / 31);
  const day = ((h + l - 7 * m + 114) % 31) + 1;
  return `${String(year)}-${String(month).padStart(2, '0')}-${String(day).padStart(2, '0')}`;
}

function isLeapYear(year: number): boolean {
  return (year % 4 === 0 && year % 100 !== 0) || year % 400 === 0;
}

/** A 29 February birthday is kept on the 28th in a year without one. */
export function isBirthdayOn(birthday: string | null | undefined, today: string): boolean {
  const match = /^(?:\d{4}|-)-(\d{2})-(\d{2})$/.exec(birthday ?? '');
  if (match === null) return false;
  const monthDay = `${match[1] ?? ''}-${match[2] ?? ''}`;
  const year = Number(today.slice(0, 4));
  const kept = monthDay === '02-29' && !isLeapYear(year) ? '02-28' : monthDay;
  return today.slice(5) === kept;
}

function withinMonthDays(monthDay: string, from: string, to: string): boolean {
  return from <= to ? monthDay >= from && monthDay <= to : monthDay >= from || monthDay <= to;
}

export function momentIsOn(rule: MomentRule, day: MomentDay): boolean {
  switch (rule.kind) {
    case 'birthday':
      return isBirthdayOn(day.birthday, day.today);
    case 'dates':
      return (
        (rule.hemisphere === undefined || rule.hemisphere === day.hemisphere) &&
        withinMonthDays(day.today.slice(5), rule.from, rule.to)
      );
    case 'easter': {
      const easter = easterSunday(Number(day.today.slice(0, 4)));
      return day.today >= addDays(easter, rule.from) && day.today <= addDays(easter, rule.to);
    }
  }
}

/**
 * What a member wears today: a birthday moment always takes its slot;
 * otherwise the first moment on, in catalogue order, fills a slot nothing is
 * worn in. At most one moment a slot; a face moment only on a Nestling.
 */
export function layersOn(
  wear: AvatarWear,
  day: MomentDay,
  onNestling: boolean,
  moments: typeof MOMENTS = MOMENTS,
): AvatarLayer[] {
  const on = moments.filter(
    (moment) => (moment.slot !== 'face' || onNestling) && momentIsOn(moment.rule, day),
  );
  return AVATAR_SLOTS.flatMap((slot): AvatarLayer[] => {
    const birthday = on.find((moment) => moment.slot === slot && moment.rule.kind === 'birthday');
    if (birthday !== undefined) return [{ slot, id: birthday.id }];
    const worn = wear[slot];
    if (worn !== undefined) return [{ slot, id: worn }];
    const moment = on.find((candidate) => candidate.slot === slot);
    return moment === undefined ? [] : [{ slot, id: moment.id }];
  });
}
