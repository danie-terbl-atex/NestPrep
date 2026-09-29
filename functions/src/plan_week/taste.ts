import { addDays } from '../school_letter/plain_date';
import { HISTORY_WEEKS } from './iso_week';
import { LUNCH_SLOTS, slotKey, type LunchPlanFacts } from './week_documents';

/**
 * What one child's history says about each item — the app's `LunchTaste`, the
 * same transparent tally (lunch-box ADR-0003): eaten on its own +2, with the
 * box +1; left on its own −3, with the box −1; the last four weeks in full,
 * the four before at half, older not at all. Item id → score.
 *
 * The model is told the score as a word ("loved", "eaten", "left"), never a
 * child's history itself.
 */
export function tasteFrom(
  history: readonly LunchPlanFacts[],
  currentMonday: string,
): ReadonlyMap<string, number> {
  const scores: Record<string, number> = {};
  for (const plan of history) {
    const weeksAgo = Math.round(
      (Date.parse(`${currentMonday}T12:00:00Z`) - Date.parse(`${plan.weekStart}T12:00:00Z`)) /
        (7 * 86_400_000),
    );
    const recency = recencyWeight(weeksAgo);
    if (recency === 0) continue;
    for (const [day, mark] of Object.entries(plan.feedback)) {
      for (const slot of LUNCH_SLOTS) {
        const pick = plan.slots[slotKey(Number(day), slot)];
        const own = mark.items[slot];
        const verdict = own === 'ate' || own === 'left' ? own : mark.verdict;
        if (pick === undefined) continue;
        const onItsOwn = own === 'ate' || own === 'left';
        const points = verdict === 'ate' ? (onItsOwn ? 2 : 1) : onItsOwn ? -3 : -1;
        scores[pick.itemId] = (scores[pick.itemId] ?? 0) + points * recency;
      }
    }
  }
  return new Map(Object.entries(scores));
}

export function recencyWeight(weeksAgo: number): number {
  if (weeksAgo < 0) return 0;
  if (weeksAgo < HISTORY_WEEKS / 2) return 1;
  if (weeksAgo <= HISTORY_WEEKS) return 0.5;
  return 0;
}

/** The first Monday whose plans still teach anything for [currentMonday]. */
export function historyStart(currentMonday: string): string {
  return addDays(currentMonday, -7 * HISTORY_WEEKS);
}

/** A score as the one word the model is told. */
export type TasteWord = 'loved' | 'eaten' | 'new' | 'mixed' | 'left';

export function tasteWord(score: number | undefined, isLiked: boolean): TasteWord {
  if (score === undefined || score === 0) return isLiked ? 'loved' : 'new';
  if (score >= 3 || (isLiked && score > 0)) return 'loved';
  if (score > 0) return 'eaten';
  if (score <= -3) return 'left';
  return 'mixed';
}
