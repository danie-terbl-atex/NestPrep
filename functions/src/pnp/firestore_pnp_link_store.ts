import { type DocumentReference, type Firestore, Timestamp } from 'firebase-admin/firestore';
import { z } from 'zod';

import type {
  PendingPnpLink,
  PnpLink,
  PnpLinkStore,
  PnpSessionLink,
  SessionSwap,
} from './pnp_link_store';

export const PNP_LINKS = 'pnpLinks';

export function pnpLinkRef(store: Firestore, uid: string): DocumentReference {
  return store.collection(PNP_LINKS).doc(uid);
}

const timestamp = z.instanceof(Timestamp).transform((value) => value.toDate());

const storedLink = z.object({
  pending: z.object({ sealed: z.string(), expiresAt: timestamp }).nullable(),
  session: z
    .object({ sealed: z.string(), accessExpiresAt: timestamp, linkedAt: timestamp })
    .nullable(),
});

/** A stored link, read and never cast (ENG-09); one that does not read is no link. */
export function pnpLinkOf(data: unknown): PnpLink | null {
  const parsed = storedLink.safeParse(data);
  return parsed.success ? parsed.data : null;
}

function documentOf(link: PnpLink): Record<string, unknown> {
  const { pending, session } = link;
  return {
    pending:
      pending === null
        ? null
        : { sealed: pending.sealed, expiresAt: Timestamp.fromDate(pending.expiresAt) },
    session:
      session === null
        ? null
        : {
            sealed: session.sealed,
            accessExpiresAt: Timestamp.fromDate(session.accessExpiresAt),
            linkedAt: Timestamp.fromDate(session.linkedAt),
          },
    updatedAt: Timestamp.now(),
  };
}

/**
 * `pnpLinks/{uid}` in Firestore. Every write reads the link and replaces it
 * whole inside one transaction, so a pending link claimed by one completion
 * cannot also be claimed by a second racing it (BE-06).
 */
export class FirestorePnpLinkStore implements PnpLinkStore {
  constructor(private readonly store: Firestore) {}

  async read(uid: string): Promise<PnpLink | null> {
    return pnpLinkOf((await pnpLinkRef(this.store, uid).get()).data());
  }

  savePending(uid: string, pending: PendingPnpLink): Promise<void> {
    return this.change(uid, (link) => ({ pending, session: link?.session ?? null }));
  }

  async claimPending(uid: string, now: Date): Promise<PendingPnpLink | null> {
    const ref = pnpLinkRef(this.store, uid);
    return this.store.runTransaction(async (transaction) => {
      const link = pnpLinkOf((await transaction.get(ref)).data());
      const pending = link?.pending ?? null;
      if (link === null || pending === null) return null;
      transaction.set(ref, documentOf({ ...link, pending: null }));
      return pending.expiresAt > now ? pending : null;
    });
  }

  saveSession(uid: string, session: PnpSessionLink): Promise<void> {
    return this.change(uid, () => ({ pending: null, session }));
  }

  async replaceSession(
    uid: string,
    expectedSealed: string,
    next: PnpSessionLink,
  ): Promise<SessionSwap> {
    const ref = pnpLinkRef(this.store, uid);
    return this.store.runTransaction(async (transaction) => {
      const link = pnpLinkOf((await transaction.get(ref)).data());
      if (link?.session == null) return 'gone';
      if (link.session.sealed !== expectedSealed) return 'changed';
      transaction.set(ref, documentOf({ ...link, session: next }));
      return 'replaced';
    });
  }

  async remove(uid: string): Promise<void> {
    const ref = pnpLinkRef(this.store, uid);
    await this.store.runTransaction((transaction) => {
      transaction.delete(ref);
      return Promise.resolve();
    });
  }

  private async change(uid: string, update: (link: PnpLink | null) => PnpLink): Promise<void> {
    const ref = pnpLinkRef(this.store, uid);
    await this.store.runTransaction(async (transaction) => {
      const link = pnpLinkOf((await transaction.get(ref)).data());
      transaction.set(ref, documentOf(update(link)));
    });
  }
}
