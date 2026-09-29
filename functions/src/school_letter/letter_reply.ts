import { z } from 'zod';

import type { ChildHint } from './child_hints';
import { addDays, isoWeekday, parseDay } from './plain_date';

/** More than a newsletter ever holds; the rest are dropped (BE-08). */
export const MAX_PROPOSALS = 25;

/**
 * The model's answer as it must parse (ENG-09). Loose where the model is
 * allowed to be vague — a missing note or end time is fine — and every value
 * is then checked again by `proposalsFrom`, because a date the model *wrote*
 * is not a date that exists.
 */
export const letterReply = z.object({
  events: z
    .array(
      z.object({
        title: z.string(),
        date: z.string(),
        allDay: z.boolean(),
        startTime: z.string().nullable().optional(),
        endTime: z.string().nullable().optional(),
        repeat: z.enum(['none', 'daily', 'weekly', 'monthly']).catch('none'),
        repeatUntil: z.string().nullable().optional(),
        children: z.array(z.string()).catch([]),
        note: z.string().nullable().optional(),
      }),
    )
    .max(MAX_PROPOSALS * 2),
});
export type LetterReply = z.infer<typeof letterReply>;

/** A recurrence rule in the exact shape the app stores (foundation ADR-0005). */
export interface ProposedRecurrence {
  readonly frequency: 'daily' | 'weekly' | 'monthly';
  readonly interval: 1;
  readonly weekdays: number[];
  readonly until: string | null;
}

/**
 * One event the letter proposed, on the household's wall clock (calendar
 * ADR-0002) — the wire shape the app's review list is built from. Nothing is
 * saved: the parent ticks, edits and confirms (calendar ADR-0005).
 */
export interface LetterProposal {
  readonly title: string;
  readonly date: string;
  readonly startMinute: number | null;
  readonly endMinute: number | null;
  readonly recurrence: ProposedRecurrence | null;
  readonly memberIds: string[];
  readonly note: string | null;
}

/** How far back and forward a letter's dates are believed. */
export const PAST_DAYS = 31;
export const FUTURE_DAYS = 400;

const TIME = /^([01]?\d|2[0-3])[:hH.]([0-5]\d)$/;

/**
 * The model's events as proposals the app can trust: dates that exist, in a
 * believable window; times on a clock; an end after its start; children
 * mapped from placeholders back to member ids (an unknown placeholder is
 * dropped, never guessed); duplicates merged; sorted; bounded.
 */
export function proposalsFrom(
  reply: LetterReply,
  today: string,
  children: readonly ChildHint[],
): LetterProposal[] {
  const earliest = addDays(today, -PAST_DAYS);
  const latest = addDays(today, FUTURE_DAYS);
  const memberFor = new Map(children.map((child) => [child.ref, child.memberId]));
  const seen = new Set<string>();
  const proposals: LetterProposal[] = [];

  for (const event of reply.events) {
    const title = tidy(event.title, 100);
    const date = parseDay(event.date.trim());
    if (title === null || date === null || date < earliest || date > latest) continue;
    const start = event.allDay ? null : minuteOf(event.startTime);
    const rawEnd = start === null ? null : minuteOf(event.endTime);
    const end = rawEnd !== null && start !== null && rawEnd > start ? rawEnd : null;
    const key = `${title.toLowerCase()}|${date}|${String(start)}`;
    if (seen.has(key)) continue;
    seen.add(key);
    proposals.push({
      title,
      date,
      startMinute: start,
      endMinute: end,
      recurrence: recurrenceOf(event.repeat, date, event.repeatUntil),
      memberIds: [...new Set(event.children.flatMap((ref) => memberFor.get(ref.trim()) ?? []))],
      note: tidy(event.note ?? null, 200),
    });
  }

  return proposals
    .sort((a, b) => a.date.localeCompare(b.date) || (a.startMinute ?? -1) - (b.startMinute ?? -1))
    .slice(0, MAX_PROPOSALS);
}

function recurrenceOf(
  repeat: LetterReply['events'][number]['repeat'],
  date: string,
  until: string | null | undefined,
): ProposedRecurrence | null {
  if (repeat === 'none') return null;
  const end = until === null || until === undefined ? null : parseDay(until.trim());
  // A repeat that ends before it starts is a misreading; the event stays, once.
  if (end !== null && end < date) return null;
  return {
    frequency: repeat,
    interval: 1,
    weekdays: repeat === 'weekly' ? [isoWeekday(date)] : [],
    until: end,
  };
}

function minuteOf(value: string | null | undefined): number | null {
  const match = TIME.exec(value?.trim() ?? '');
  if (match === null) return null;
  return Number(match[1]) * 60 + Number(match[2]);
}

function tidy(value: string | null, max: number): string | null {
  const collapsed = value?.replace(/\s+/g, ' ').trim() ?? '';
  return collapsed === '' ? null : collapsed.slice(0, max);
}
