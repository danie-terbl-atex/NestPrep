import { onCall } from 'firebase-functions/v2/https';
import { logger } from 'firebase-functions/v2';

import { db } from '../shared/firestore';
import { readHousehold, roleOf } from '../household/documents';
import { parseInput, requireUid } from '../household/parse_input';
import { documentsInFolder, folderRef } from './document_refs';
import { refuseDocument } from './errors';
import { deleteDocumentFolderInput } from './schemas';

/**
 * Deleting a folder is here rather than in `firestore.rules` for one reason:
 * a rule cannot count the documents in a collection (foundation ADR-0002).
 *
 * Without that count, a folder can be deleted out from under its documents,
 * and then those documents are unreachable while their bytes stay in the
 * bucket and stay billed — the exact failure the shared id was chosen to make
 * findable. So the folder must be empty first, and this is the only thing that
 * can say whether it is (documents ADR-0001).
 *
 * The check and the delete are one transaction, so a document added while the
 * folder was being deleted does not end up orphaned by a decision made a
 * moment earlier (BE-06, BE-07).
 */
export const deleteDocumentFolder = onCall(async (request) => {
  const uid = requireUid(request.auth);
  const input = parseInput(deleteDocumentFolderInput, request.data);
  const store = db();

  await store.runTransaction(async (transaction) => {
    const household = await readHousehold(transaction, store, input.householdId, () =>
      refuseDocument('notAMember'),
    );
    const role = roleOf(household, uid);
    if (role === undefined) throw refuseDocument('notAMember');
    if (role !== 'admin') throw refuseDocument('notAnAdmin');

    const folder = folderRef(store, input.householdId, input.folderId);
    const snapshot = await transaction.get(folder);
    if (!snapshot.exists) throw refuseDocument('folderNotFound');

    const filed = await transaction.get(
      documentsInFolder(store, input.householdId, input.folderId),
    );
    if (!filed.empty) throw refuseDocument('folderNotEmpty');

    transaction.delete(folder);
  });

  logger.info('document folder deleted', { householdId: input.householdId });
  return { folderId: input.folderId };
});
