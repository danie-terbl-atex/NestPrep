import { type DocumentReference, type Firestore, Timestamp } from 'firebase-admin/firestore';
import { z } from 'zod';

import type { StoreContext } from './checkers_api';
import type {
  CheckersLink,
  CheckersLinkStore,
  ClaimedAttempt,
  PendingLink,
  SessionLink,
} from './link_store';

export const CHECKERS_LINKS = 'checkersLinks';

export function checkersLinkRef(store: Firestore, uid: string): DocumentReference {
  return store.collection(CHECKERS_LINKS).doc(uid);
}

const timestamp = z.instanceof(Timestamp).transform((value) => value.toDate());

const storedStore = z.object({
  storeId: z.string(),
  serviceOptionIds: z.array(z.string()),
  hasCapacity: z.array(z.string()),
  brandPriority: z.number().nullable(),
  distanceFromCustomer: z.number().nullable(),
});

const storedLink = z.object({
  deviceId: z.string().min(1),
  pending: z
    .object({
      sealed: z.string(),
      expiresAt: timestamp,
      attempts: z.number().int(),
      mobileMasked: z.string(),
    })
    .nullable(),
  session: z
    .object({
      sealed: z.string(),
      expiresAt: timestamp,
      storeContexts: z.array(storedStore),
      mobileMasked: z.string(),
    })
    .nullable(),
});

/** A stored link, read and never cast (ENG-09); one that does not read is no link. */
export function linkOf(data: unknown): CheckersLink | null {
  const parsed = storedLink.safeParse(data);
  return parsed.success ? parsed.data : null;
}

function storesToStore(stores: readonly StoreContext[]): Record<string, unknown>[] {
  return stores.map((context) => ({ ...context }));
}

function pendingToStore(pending: PendingLink | null): Record<string, unknown> | null {
  return pending === null ? null : { ...pending, expiresAt: Timestamp.fromDate(pending.expiresAt) };
}

function sessionToStore(session: SessionLink | null): Record<string, unknown> | null {
  if (session === null) return null;
  return {
    ...session,
    expiresAt: Timestamp.fromDate(session.expiresAt),
    storeContexts: storesToStore(session.storeContexts),
  };
}

function documentOf(link: CheckersLink): Record<string, unknown> {
  return {
    deviceId: link.deviceId,
    pending: pendingToStore(link.pending),
    session: sessionToStore(link.session),
    updatedAt: Timestamp.now(),
  };
}

/**
 * `checkersLinks/{uid}` in Firestore. Every write reads the link first and
 * replaces it whole inside one transaction, so a code claimed by one attempt
 * cannot also be claimed by a second attempt racing it (BE-06).
 */
export class FirestoreLinkStore implements CheckersLinkStore {
  constructor(private readonly store: Firestore) {}

  async read(uid: string): Promise<CheckersLink | null> {
    return linkOf((await checkersLinkRef(this.store, uid).get()).data());
  }

  savePending(uid: string, deviceId: string, pending: PendingLink): Promise<void> {
    return this.change(uid, (link) => ({ deviceId, pending, session: link?.session ?? null }));
  }

  async claimAttempt(uid: string, now: Date, maxAttempts: number): Promise<ClaimedAttempt | null> {
    const ref = checkersLinkRef(this.store, uid);
    return this.store.runTransaction(async (transaction) => {
      const link = linkOf((await transaction.get(ref)).data());
      const pending = link?.pending ?? null;
      if (link === null || pending === null) return null;
      const isLive = pending.expiresAt > now && pending.attempts < maxAttempts;
      const next = isLive ? { ...pending, attempts: pending.attempts + 1 } : null;
      transaction.set(ref, documentOf({ ...link, pending: next }));
      return next === null ? null : { deviceId: link.deviceId, pending: next };
    });
  }

  saveSession(uid: string, deviceId: string, session: SessionLink): Promise<void> {
    return this.change(uid, () => ({ deviceId, pending: null, session }));
  }

  async remove(uid: string): Promise<void> {
    const ref = checkersLinkRef(this.store, uid);
    await this.store.runTransaction((transaction) => {
      transaction.delete(ref);
      return Promise.resolve();
    });
  }

  private async change(
    uid: string,
    update: (link: CheckersLink | null) => CheckersLink,
  ): Promise<void> {
    const ref = checkersLinkRef(this.store, uid);
    await this.store.runTransaction(async (transaction) => {
      const link = linkOf((await transaction.get(ref)).data());
      transaction.set(ref, documentOf(update(link)));
    });
  }
}
