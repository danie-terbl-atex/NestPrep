import type { DocumentReference, Firestore, Query } from 'firebase-admin/firestore';

import { HOUSEHOLDS } from '../household/documents';

/**
 * Where a household's documents live (documents ADR-0001). One level of
 * folders, and a document names the folder it is in rather than nesting under
 * it — so moving one is a field, not a copy, and the whole household's
 * documents are one bounded read.
 */
export const DOCUMENT_FOLDERS = 'documentFolders';
export const DOCUMENTS = 'documents';

export function folderRef(
  store: Firestore,
  householdId: string,
  folderId: string,
): DocumentReference {
  return store.collection(HOUSEHOLDS).doc(householdId).collection(DOCUMENT_FOLDERS).doc(folderId);
}

/**
 * Anything still filed in a folder. Bounded to one, because the only question
 * ever asked of it is "is this folder empty" and reading the whole collection
 * to answer it would be a bill that grows with the household (BE-08).
 */
export function documentsInFolder(store: Firestore, householdId: string, folderId: string): Query {
  return store
    .collection(HOUSEHOLDS)
    .doc(householdId)
    .collection(DOCUMENTS)
    .where('folderId', '==', folderId)
    .limit(1);
}
