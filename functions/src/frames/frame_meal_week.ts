import { addDays } from '../calendar_sync/zoned_time';
import { type FrameMealSlot, type MealDay, MEAL_SLOTS, mealSlotsOn, mondayOf } from './frame_day';

/**
 * A week of the household's meal plan for the frame's Meals overview
 * (NestPrep-Home ADR-0029): this week or the next, never further, read only
 * while someone has the overview open, so the day's minute-by-minute read
 * never pays for it.
 */

export const FRAME_MEAL_WEEKS = ['this', 'next'] as const;
export type FrameMealWeek = (typeof FRAME_MEAL_WEEKS)[number];

export interface FrameMealWeekSources {
  readonly today: string;
  /** The Monday that names the week. */
  readonly week: string;
  /** Absent when the frame's meals panel is off. */
  readonly meals?: MealDay;
}

export interface FrameMeals {
  readonly status: 'linked';
  readonly today: string;
  readonly week: string;
  readonly days: { readonly date: string; readonly slots: FrameMealSlot[] }[];
}

export function mealWeekOf(today: string, week: FrameMealWeek): string {
  return addDays(mondayOf(today), week === 'next' ? 7 : 0);
}

/** Every meal id the week plans, for one read of their names and photos. */
export function plannedMealIds(slots: Readonly<Record<string, string>>): string[] {
  return Array.from({ length: 7 }, (_, offset) => offset + 1).flatMap((weekday) =>
    MEAL_SLOTS.flatMap((slot) => slots[`${String(weekday)}_${slot}`] ?? []),
  );
}

export function assembleFrameMeals(sources: FrameMealWeekSources): FrameMeals {
  const { today, week, meals } = sources;
  const days =
    meals === undefined
      ? []
      : Array.from({ length: 7 }, (_, offset) => ({
          date: addDays(week, offset),
          slots: mealSlotsOn(meals, offset + 1),
        }));
  return { status: 'linked', today, week, days };
}
