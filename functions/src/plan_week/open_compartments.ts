import { SCHOOL_DAYS } from './iso_week';
import { LUNCH_SLOTS, slotKey, type LunchPlanFacts } from './week_documents';

/**
 * A child's empty compartments this week, as `{day}_{slot}` — a treat on
 * Friday only (lunch-box ADR-0003). What a person packed is never planned
 * over, so a filled compartment is simply not open.
 */
export function openCompartments(thisWeek: LunchPlanFacts | undefined): string[] {
  const open: string[] = [];
  for (const day of SCHOOL_DAYS) {
    for (const slot of LUNCH_SLOTS) {
      if (slot === 'treat' && day !== 5) continue;
      if (thisWeek?.slots[slotKey(day, slot)] !== undefined) continue;
      open.push(slotKey(day, slot));
    }
  }
  return open;
}
