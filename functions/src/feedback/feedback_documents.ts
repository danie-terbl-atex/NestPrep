import type { Firestore } from 'firebase-admin/firestore';

/**
 * Created by the app, read only by admin tools through the Admin SDK
 * (feedback ADR-0001). `uid` is how erasure and Download my data find a
 * person's own.
 */
export const FEEDBACK = 'feedback';

export const FEEDBACK_EXPORT_LIMIT = 500;

const ERASE_PAGE = 400;

export function feedbackOf(store: Firestore, uid: string): FirebaseFirestore.Query {
  return store.collection(FEEDBACK).where('uid', '==', uid);
}

/** Deleted rather than anonymised: free text about a family is personal whoever sent it. */
export async function deleteFeedbackOf(store: Firestore, uid: string): Promise<void> {
  for (;;) {
    const page = await feedbackOf(store, uid).limit(ERASE_PAGE).get();
    if (page.empty) return;
    const batch = store.batch();
    for (const entry of page.docs) batch.delete(entry.ref);
    await batch.commit();
    if (page.size < ERASE_PAGE) return;
  }
}
