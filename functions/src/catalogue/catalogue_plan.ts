import { z } from 'zod';

/**
 * How a system-owned catalogue (recipes, starter boxes — recipes ADR-0001,
 * lunch-box ADR-0018) moves from source to Firestore: ids are fixed, a
 * document's `version` rises only when its content changes, and an id gone
 * from the source is retired, never deleted, because household items keep it.
 * Pure, so the rules of publishing are tested without a database (BE-14).
 */

export const CATALOGUE_STATUSES = ['published', 'retired'] as const;
export type CatalogueStatus = (typeof CATALOGUE_STATUSES)[number];

/** What one entry's document holds besides its status, version and time. */
export type CatalogueFields = Readonly<Record<string, unknown>>;

export interface CatalogueEntry {
  readonly id: string;
  readonly fields: CatalogueFields;
}

/** A stored document, as far as publishing needs to know it. */
export interface StoredCatalogueEntry {
  readonly status: CatalogueStatus;
  readonly version: number;
  /** Everything else it holds, compared with the source's fields. */
  readonly content: CatalogueFields;
}

export type CatalogueWrite =
  | {
      readonly kind: 'publish';
      readonly id: string;
      readonly version: number;
      readonly fields: CatalogueFields;
    }
  | { readonly kind: 'retire'; readonly id: string; readonly version: number };

export interface CataloguePlan {
  readonly writes: readonly CatalogueWrite[];
  readonly unchanged: number;
}

const storedShape = z
  .object({ status: z.enum(CATALOGUE_STATUSES), version: z.number().int().min(1) })
  .loose();

/** A stored document parsed (ENG-09); one that is not a catalogue entry throws. */
export function storedCatalogueEntry(id: string, data: unknown): StoredCatalogueEntry {
  const parsed = storedShape.safeParse(data);
  if (!parsed.success)
    throw new Error(`stored catalogue entry ${id} is not one: ${parsed.error.message}`);
  const { status, version, ...rest } = parsed.data;
  const content = Object.fromEntries(Object.entries(rest).filter(([key]) => key !== 'updatedAt'));
  return { status, version, content };
}

/**
 * The writes that bring [stored] in line with [entries]: a new id is published
 * at version 1; a changed or retired one is republished one version up; an id
 * no longer in the source is retired one version up; the rest are left alone,
 * so running it twice writes nothing the second time.
 */
export function planCatalogue(
  entries: readonly CatalogueEntry[],
  stored: ReadonlyMap<string, StoredCatalogueEntry>,
): CataloguePlan {
  const ids = new Set(entries.map(({ id }) => id));
  if (ids.size !== entries.length) throw new Error('a catalogue id is used twice');
  const writes: CatalogueWrite[] = [];
  let unchanged = 0;
  for (const { id, fields } of entries) {
    const existing = stored.get(id);
    if (existing === undefined) {
      writes.push({ kind: 'publish', id, version: 1, fields });
    } else if (existing.status !== 'published' || !sameContent(existing.content, fields)) {
      writes.push({ kind: 'publish', id, version: existing.version + 1, fields });
    } else {
      unchanged += 1;
    }
  }
  for (const [id, existing] of stored) {
    if (ids.has(id)) continue;
    if (existing.status === 'retired') unchanged += 1;
    else writes.push({ kind: 'retire', id, version: existing.version + 1 });
  }
  return { writes, unchanged };
}

function sameContent(stored: CatalogueFields, source: CatalogueFields): boolean {
  return canonical(stored) === canonical(source);
}

/** JSON with every object's keys sorted, so key order never reads as a change. */
function canonical(value: unknown): string {
  return JSON.stringify(value, (_key, inner: unknown) =>
    inner !== null && typeof inner === 'object' && !Array.isArray(inner)
      ? Object.fromEntries(Object.entries(inner).sort(([a], [b]) => (a < b ? -1 : a > b ? 1 : 0)))
      : inner,
  );
}
