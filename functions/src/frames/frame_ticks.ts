import { addDays } from '../calendar_sync/zoned_time';
import { firstName } from './frame_day';
import { FRAME_OVERDUE_DAYS } from './frame_policy';

/**
 * The rules of a tick from the wall (photo-frames ADR-0007), pure so they are
 * tested where they live (`BE-14`).
 */

/** Today and the overdue window behind it, in the household's zone. */
export function inTickReach(date: string, today: string): boolean {
  return date <= today && date >= addDays(today, -FRAME_OVERDUE_DAYS);
}

/**
 * The member a tick credits: the only one who could have done it, or the one
 * eligible member whose first name is [by]. Null when that is not exactly one.
 */
export function creditFor(
  eligible: readonly string[],
  names: Readonly<Record<string, string>>,
  by: string | null,
): string | null {
  if (eligible.length === 1) return eligible[0] ?? null;
  if (by === null) return null;
  const matches = membersNamed(eligible, names, by);
  return matches.length === 1 ? (matches[0] ?? null) : null;
}

/** Those of [ids] whose first name is [name], in any case. */
export function membersNamed(
  ids: readonly string[],
  names: Readonly<Record<string, string>>,
  name: string,
): string[] {
  const wanted = name.trim().toLocaleLowerCase();
  return ids.filter((id) => firstName(names[id] ?? '').toLocaleLowerCase() === wanted);
}

/** A routine's ticked steps after one step, or all of them ([step] null), is set to [done]. */
export function nextTicks(
  itemIds: readonly string[],
  ticked: readonly string[],
  step: string | null,
  done: boolean,
): string[] {
  if (step === null) return done ? [...itemIds] : [];
  return itemIds.filter((id) => (id === step ? done : ticked.includes(id)));
}
