import { type DocumentReference, type Firestore, Timestamp } from 'firebase-admin/firestore';
import { z } from 'zod';

import type {
  SessionSwap,
  WoolworthsLink,
  WoolworthsLinkStore,
  WoolworthsSessionLink,
} from './woolworths_link_store';

export const WOOLWORTHS_LINKS = 'woolworthsLinks';

export function woolworthsLinkRef(store: Firestore, uid: string): DocumentReference {
  return store.collection(WOOLWORTHS_LINKS).doc(uid);
}

const timestamp = z.instanceof(Timestamp).transform((value) => value.toDate());

const storedLink = z.object({
  session: z
    .object({
      sealed: z.string(),
      idExpiresAt: timestamp,
      linkedAt: timestamp,
      emailMasked: z
        .string()
        .nullish()
        .transform((value) => value ?? null),
    })
    .nullable(),
});

export function woolworthsLinkOf(data: unknown): WoolworthsLink | null {
  const parsed = storedLink.safeParse(data);
  return parsed.success ? parsed.data : null;
}

function documentOf(session: WoolworthsSessionLink): Record<string, unknown> {
  return {
    session: {
      sealed: session.sealed,
      idExpiresAt: Timestamp.fromDate(session.idExpiresAt),
      linkedAt: Timestamp.fromDate(session.linkedAt),
      emailMasked: session.emailMasked,
    },
    updatedAt: Timestamp.now(),
  };
}

export class FirestoreWoolworthsLinkStore implements WoolworthsLinkStore {
  constructor(private readonly store: Firestore) {}

  async read(uid: string): Promise<WoolworthsLink | null> {
    return woolworthsLinkOf((await woolworthsLinkRef(this.store, uid).get()).data());
  }

  async saveSession(uid: string, session: WoolworthsSessionLink): Promise<void> {
    const ref = woolworthsLinkRef(this.store, uid);
    await this.store.runTransaction((transaction) => {
      transaction.set(ref, documentOf(session));
      return Promise.resolve();
    });
  }

  async replaceSession(
    uid: string,
    expectedSealed: string,
    next: WoolworthsSessionLink,
  ): Promise<SessionSwap> {
    const ref = woolworthsLinkRef(this.store, uid);
    return this.store.runTransaction(async (transaction) => {
      const link = woolworthsLinkOf((await transaction.get(ref)).data());
      if (link?.session == null) return 'gone';
      if (link.session.sealed !== expectedSealed) return 'changed';
      transaction.set(ref, documentOf(next));
      return 'replaced';
    });
  }

  async remove(uid: string): Promise<void> {
    const ref = woolworthsLinkRef(this.store, uid);
    await this.store.runTransaction((transaction) => {
      transaction.delete(ref);
      return Promise.resolve();
    });
  }
}
