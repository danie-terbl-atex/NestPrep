import { doc, onSnapshot, type DocumentSnapshot, type Unsubscribe } from 'firebase/firestore';

import { type Firestore } from './rules_harness';

/** Cancels every listener the running test opened, whatever the test did. */
const open: Unsubscribe[] = [];

export function stopWatching(): void {
  while (open.length > 0) open.pop()?.();
}

/**
 * Opens a listener on one document as one member and resolves when a
 * server-confirmed snapshot satisfies [untilSeen] — or rejects, loudly, if none
 * ever does. Waiting on the callback is what makes this a liveness check rather
 * than a read, and refusing a `fromCache` snapshot is what makes it a check on
 * what the *other* member's client was actually told.
 */
export function watchDoc(
  db: Firestore,
  path: string,
  untilSeen: (snapshot: DocumentSnapshot) => boolean,
): Promise<DocumentSnapshot> {
  return new Promise((resolve, reject) => {
    const timer = setTimeout(() => {
      reject(new Error(`nothing arrived on ${path} within 10s`));
    }, 10_000);
    const stop = onSnapshot(
      doc(db, path),
      { includeMetadataChanges: true },
      (snapshot) => {
        if (snapshot.metadata.fromCache || !untilSeen(snapshot)) return;
        clearTimeout(timer);
        resolve(snapshot);
      },
      (error) => {
        clearTimeout(timer);
        reject(error);
      },
    );
    open.push(stop);
  });
}

/** True once the document is gone from the server's point of view. */
export function watchGone(db: Firestore, path: string): Promise<DocumentSnapshot> {
  return watchDoc(db, path, (snapshot) => !snapshot.exists());
}
