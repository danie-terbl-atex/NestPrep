import type { Firestore, Transaction } from 'firebase-admin/firestore';

type Documents = Readonly<Record<string, Readonly<Record<string, unknown>>>>;

/** Just enough of Firestore to read documents by path: what a premium check asks of it. */
export function storeOf(documents: Documents): Firestore {
  const collectionAt = (path: string): unknown => ({
    doc: (id: string) => refAt(`${path}/${id}`),
  });
  const refAt = (path: string): unknown => ({
    get: (): Promise<unknown> => {
      const data = documents[path];
      return Promise.resolve({
        exists: data !== undefined,
        data: () => data,
        get: (field: string) => data?.[field],
      });
    },
    collection: (name: string) => collectionAt(`${path}/${name}`),
  });
  return { collection: collectionAt } as unknown as Firestore;
}

export const readingTransaction = {
  get: (ref: { get: () => Promise<unknown> }) => ref.get(),
} as unknown as Transaction;
