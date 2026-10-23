import { addDays } from '../school_letter/plain_date';
import { SCHOOL_DAYS, type SchoolDay } from './iso_week';
import { DEFAULT_TREAT_DAYS } from './packing_preferences';
import { LUNCH_SLOTS, slotKey, type LunchPlanFacts, type LunchSlot } from './week_documents';

/** The school week being planned, and the household's today, both `YYYY-MM-DD`. */
export interface SchoolWeek {
  readonly monday: string;
  /** Today on the household's clock (`todayIn`), never the server's. */
  readonly today: string;
}

/**
 * Whether school day [day] (ISO weekday) of [week] has gone: today or earlier,
 * so its box is packed or eaten — what the app's `LunchDay.hasHappened` says
 * (lunch-box ADR-0019). Plain dates compare as text.
 */
export function hasGone(week: SchoolWeek, day: number): boolean {
  return addDays(week.monday, day - 1) <= week.today;
}

/**
 * A child's empty compartments this week, as `{day}_{slot}` — a treat only on
 * the parent's treat days, Friday when they did not say (lunch-box ADR-0025,
 * amending ADR-0003 for *Plan my week*). What a person packed is never planned
 * over, so a filled compartment is simply not open; nor is a kind of
 * compartment the parent chose not to plan, nor a school day that has gone.
 */
export function openCompartments(
  thisWeek: LunchPlanFacts | undefined,
  week: SchoolWeek,
  slots: readonly LunchSlot[] = LUNCH_SLOTS,
  treatDays: readonly SchoolDay[] = DEFAULT_TREAT_DAYS,
): string[] {
  const open: string[] = [];
  for (const day of SCHOOL_DAYS) {
    if (hasGone(week, day)) continue;
    for (const slot of slots) {
      if (slot === 'treat' && !treatDays.includes(day)) continue;
      if (thisWeek?.slots[slotKey(day, slot)] !== undefined) continue;
      open.push(slotKey(day, slot));
    }
  }
  return open;
}
