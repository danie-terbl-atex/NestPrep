import { SCHOOL_DAYS } from './iso_week';
import { LUNCH_SLOTS, slotKey, type LunchPlanFacts, type LunchSlot } from './week_documents';

/**
 * A child's empty compartments this week, as `{day}_{slot}` — a treat on
 * Friday only (lunch-box ADR-0003). What a person packed is never planned
 * over, so a filled compartment is simply not open; nor is a kind of
 * compartment the parent chose not to plan.
 */
export function openCompartments(
  thisWeek: LunchPlanFacts | undefined,
  slots: readonly LunchSlot[] = LUNCH_SLOTS,
): string[] {
  const open: string[] = [];
  for (const day of SCHOOL_DAYS) {
    for (const slot of slots) {
      if (slot === 'treat' && day !== 5) continue;
      if (thisWeek?.slots[slotKey(day, slot)] !== undefined) continue;
      open.push(slotKey(day, slot));
    }
  }
  return open;
}
