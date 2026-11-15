import type { Firestore } from 'firebase-admin/firestore';
import { describe, expect, it } from 'vitest';

import { recountHouseholdSize } from '../../../src/household/keep_household_size';

type Documents = Map<string, Record<string, unknown>>;

interface Ref {
  path: string;
  collection: (name: string) => Collection;
}

interface Collection {
  doc: (id: string) => Ref;
  count: () => { prefix: string };
}

/** As much of a Firestore as a recount touches: one transaction over a map of paths. */
function storeOf(documents: Documents): Firestore {
  const collection = (prefix: string): Collection => ({
    doc: (id: string): Ref => ref(`${prefix}/${id}`),
    count: (): { prefix: string } => ({ prefix }),
  });
  const ref = (path: string): Ref => ({
    path,
    collection: (name: string): Collection => collection(`${path}/${name}`),
  });
  const transaction = {
    get: (target: Ref | { prefix: string }): Promise<unknown> => {
      if ('prefix' in target) {
        const direct = new RegExp(`^${target.prefix}/[^/]+$`);
        const count = [...documents.keys()].filter((path) => direct.test(path)).length;
        return Promise.resolve({ data: () => ({ count }) });
      }
      return Promise.resolve({ exists: documents.has(target.path), ref: target });
    },
    set: (target: Ref, data: Record<string, unknown>): void => {
      documents.set(target.path, data);
    },
    delete: (target: Ref): void => {
      documents.delete(target.path);
    },
  };
  return {
    collection,
    runTransaction: <T>(body: (staged: typeof transaction) => Promise<T>): Promise<T> =>
      body(transaction),
  } as unknown as Firestore;
}

function householdWith(people: number, stored?: number): Documents {
  const documents: Documents = new Map([['households/h1', { name: 'The Parkers' }]]);
  for (let index = 0; index < people; index += 1) {
    documents.set(`households/h1/members/m${String(index)}`, { role: 'parent' });
  }
  // Somebody's own records under a profile are not people.
  documents.set('households/h1/members/m0/notes/n1', {});
  documents.set('households/h2/members/elsewhere', { role: 'admin' });
  if (stored !== undefined) documents.set('households/h1/entitlement/size', { count: stored });
  return documents;
}

const SIZE = 'households/h1/entitlement/size';

describe('recountHouseholdSize', () => {
  it('writes how many profiles the household holds, claimed or not', async () => {
    const documents = householdWith(3);
    expect(await recountHouseholdSize(storeOf(documents), 'h1')).toBe(3);
    expect(documents.get(SIZE)).toMatchObject({ count: 3 });
    expect(documents.get(SIZE)).toHaveProperty('updatedAt');
  });

  it('counts again rather than adding one, so a wrong count heals', async () => {
    const documents = householdWith(5, 2);
    expect(await recountHouseholdSize(storeOf(documents), 'h1')).toBe(5);
    expect(documents.get(SIZE)).toMatchObject({ count: 5 });
  });

  it('comes down when somebody is removed, and the same event twice changes nothing', async () => {
    const documents = householdWith(5, 5);
    documents.delete('households/h1/members/m4');
    const store = storeOf(documents);
    expect(await recountHouseholdSize(store, 'h1')).toBe(4);
    expect(await recountHouseholdSize(store, 'h1')).toBe(4);
    expect(documents.get(SIZE)).toMatchObject({ count: 4 });
  });

  it('leaves nothing behind a household that has ended', async () => {
    const documents = householdWith(2, 3);
    documents.delete('households/h1');
    expect(await recountHouseholdSize(storeOf(documents), 'h1')).toBeNull();
    expect(documents.has(SIZE)).toBe(false);
  });
});
