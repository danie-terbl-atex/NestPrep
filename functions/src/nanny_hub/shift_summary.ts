import { Timestamp } from 'firebase-admin/firestore';
import { z } from 'zod';

/**
 * What the parents read when a shift ends (nanny-hub ADR-0002) — derived here,
 * on the server, from what the carer logged, so the summary is what happened
 * rather than what a client said happened (BE-03).
 *
 * Pure: it takes the documents as they were read and returns the fields to
 * write, so every rule about what a summary says is tested without Firestore
 * (BE-14).
 */

export const ENTRY_KINDS = [
  'meal',
  'nap',
  'nappy',
  'mood',
  'incident',
  'medicine',
  'note',
] as const;
export type EntryKind = (typeof ENTRY_KINDS)[number];

export const MOODS = ['happy', 'calm', 'tired', 'upset', 'unwell'] as const;
export type Mood = (typeof MOODS)[number];

/**
 * As many entries as a summary repeats word for word. Past it the counts still
 * cover everything; the moments say they were trimmed. It keeps one summary
 * well under a document's size however long the shift was.
 */
export const SUMMARY_MOMENT_LIMIT = 60;

/**
 * An entry as stored, read defensively: the rules checked its shape on the way
 * in, but a document is still data from outside this function (ENG-09). An
 * entry that does not parse is left out of the moments and counted nowhere,
 * and the summary says how many were unreadable rather than failing the end
 * of a shift over it.
 */
const storedEntry = z.object({
  kind: z.enum(ENTRY_KINDS),
  note: z.string().nullable().optional(),
  mood: z.enum(MOODS).nullable().optional(),
  childIds: z.array(z.string()).default([]),
  photoId: z.string().nullable().optional(),
  at: z.instanceof(Timestamp),
});

const storedChecklist = z.object({
  items: z.array(z.object({ id: z.string() }).loose()).default([]),
});

export interface SummaryMoment {
  readonly kind: EntryKind;
  readonly at: Timestamp;
  readonly note: string | null;
  readonly mood: Mood | null;
  readonly childIds: string[];
  readonly hasPhoto: boolean;
}

export interface ShiftSummaryFields {
  readonly counts: Record<EntryKind, number>;
  readonly moments: SummaryMoment[];
  readonly isTrimmed: boolean;
  readonly entryCount: number;
  readonly unreadableCount: number;
  readonly photoCount: number;
  readonly childIds: string[];
  readonly checklist: { readonly ticked: number; readonly total: number };
}

export interface ShiftRecords {
  /** The shift's entries, in any order. */
  readonly entries: readonly unknown[];
  /** The shift's `ticks` map: `moment:itemId` → true. */
  readonly ticks: unknown;
  /** Each moment's checklist document, keyed by moment; absent is empty. */
  readonly checklists: Readonly<Record<string, unknown>>;
}

function emptyCounts(): Record<EntryKind, number> {
  return Object.fromEntries(ENTRY_KINDS.map((kind) => [kind, 0])) as Record<EntryKind, number>;
}

function tickedKeys(ticks: unknown): Set<string> {
  if (ticks === null || typeof ticks !== 'object' || Array.isArray(ticks)) return new Set();
  return new Set(
    Object.entries(ticks as Record<string, unknown>)
      .filter(([, value]) => value === true)
      .map(([key]) => key),
  );
}

/** How much of the shift's checklists was done, counting only items that still exist. */
export function checklistProgress(
  ticks: unknown,
  checklists: Readonly<Record<string, unknown>>,
): { ticked: number; total: number } {
  const done = tickedKeys(ticks);
  let total = 0;
  let ticked = 0;
  for (const [moment, stored] of Object.entries(checklists)) {
    const parsed = storedChecklist.safeParse(stored);
    if (!parsed.success) continue;
    for (const item of parsed.data.items) {
      total += 1;
      if (done.has(`${moment}:${item.id}`)) ticked += 1;
    }
  }
  return { ticked, total };
}

export function summariseShift(records: ShiftRecords): ShiftSummaryFields {
  const counts = emptyCounts();
  const readable: SummaryMoment[] = [];
  const children = new Set<string>();
  let photoCount = 0;
  let unreadableCount = 0;

  for (const stored of records.entries) {
    const parsed = storedEntry.safeParse(stored);
    if (!parsed.success) {
      unreadableCount += 1;
      continue;
    }
    const entry = parsed.data;
    counts[entry.kind] += 1;
    const hasPhoto = typeof entry.photoId === 'string' && entry.photoId.length > 0;
    if (hasPhoto) photoCount += 1;
    for (const childId of entry.childIds) children.add(childId);
    readable.push({
      kind: entry.kind,
      at: entry.at,
      note: entry.note ?? null,
      mood: entry.mood ?? null,
      childIds: [...entry.childIds],
      hasPhoto,
    });
  }

  readable.sort((a, b) => a.at.toMillis() - b.at.toMillis());
  return {
    counts,
    moments: readable.slice(0, SUMMARY_MOMENT_LIMIT),
    isTrimmed: readable.length > SUMMARY_MOMENT_LIMIT,
    entryCount: readable.length,
    unreadableCount,
    photoCount,
    childIds: [...children].sort(),
    checklist: checklistProgress(records.ticks, records.checklists),
  };
}
