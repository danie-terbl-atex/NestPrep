import { addDays, daysBetween, daysInMonth, isoDate, weekdayOf } from '../calendar_sync/zoned_time';
import type { EventWindow } from '../notifications/digest_reads';
import { type FrameCalendarDay, type FrameDaySources, frameCalendarDay } from './frame_day';
import { FRAME_MONTH_REACH } from './frame_policy';

/**
 * A month of a frame's calendar (photo-frames ADR-0005), for the grid the
 * frame draws: whole weeks, Monday first, the same events the day shows.
 */

export interface FrameMonthSources {
  readonly today: string;
  /** `YYYY-MM`. */
  readonly month: string;
  readonly names: FrameDaySources['names'];
  /** Absent when the frame's calendar panel is off. */
  readonly events?: EventWindow;
}

export interface FrameMonth {
  readonly status: 'linked';
  readonly today: string;
  readonly month: string;
  readonly days: FrameCalendarDay[];
}

/** The Monday on or before the 1st to the Sunday on or after the last day. */
export function monthGrid(month: string): { readonly from: string; readonly to: string } {
  const [year, number] = month.split('-').map(Number) as [number, number];
  const first = isoDate(year, number, 1);
  const last = isoDate(year, number, daysInMonth(year, number));
  return { from: addDays(first, 1 - weekdayOf(first)), to: addDays(last, 7 - weekdayOf(last)) };
}

export function monthInReach(month: string, today: string): boolean {
  const [year, number] = month.split('-').map(Number) as [number, number];
  const [thisYear, thisMonth] = today.split('-').map(Number) as [number, number];
  return Math.abs(year * 12 + number - (thisYear * 12 + thisMonth)) <= FRAME_MONTH_REACH;
}

export function assembleFrameMonth(sources: FrameMonthSources): FrameMonth {
  const { from, to } = monthGrid(sources.month);
  const window = sources.events;
  const days =
    window === undefined
      ? []
      : Array.from({ length: daysBetween(from, to) + 1 }, (_, offset) =>
          frameCalendarDay(addDays(from, offset), window, sources.names),
        );
  return { status: 'linked', today: sources.today, month: sources.month, days };
}
