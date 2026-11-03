import { FieldValue } from 'firebase-admin/firestore';
import { onCall } from 'firebase-functions/v2/https';
import { z } from 'zod';

import { parseInput } from '../household/parse_input';
import { db } from '../shared/firestore';
import { readLinkedFrame } from './frame_access';
import { parsed } from './frame_documents';
import { refuseFrame } from './frame_errors';
import {
  GROCERY_ITEMS,
  frameGroceryId,
  frameGroceryItemDocument,
  frameProductMatch,
  groceryAdderNamed,
  sameItemOnList,
} from './frame_groceries';
import {
  FRAME_ADD_GROCERY_PER_CREDENTIAL,
  FRAME_DEVICE_OPTIONS,
  FRAME_UNBOUGHT_READ_LIMIT,
} from './frame_policy';
import { readMembersWithGrants } from './frame_reads';
import { addFrameGroceryItemInput } from './frame_schemas';

export type AddFrameGroceryItemResult =
  | { status: 'unlinked' }
  | { status: 'linked'; added: true }
  | { status: 'linked'; added: false; alreadyOnList: true };

const UNLINKED: AddFrameGroceryItemResult = { status: 'unlinked' };

const unboughtShape = z.object({
  name: z.string(),
  sourceKey: z.string().nullable().optional().catch(null),
  productMatch: z.unknown().optional(),
});

/**
 * A linked frame adds to the household's grocery list (photo-frames
 * ADR-0012), writing exactly the typed item the app would, credited to the
 * groceries editor who says they are adding it, with the product they picked
 * at the frame's shop if they did. What is already on the list and unbought
 * is not added twice; it gains the pick if it had none. A retry with the
 * same `requestId` answers added and writes nothing.
 */
export const addFrameGroceryItem = onCall(
  FRAME_DEVICE_OPTIONS,
  async (request): Promise<AddFrameGroceryItemResult> => {
    const input = parseInput(addFrameGroceryItemInput, request.data);
    const store = db();
    const linked = await readLinkedFrame(store, input.secret, FRAME_ADD_GROCERY_PER_CREDENTIAL);
    if (linked === null) return UNLINKED;
    if (linked.frame.groceries === null) throw refuseFrame('groceriesOff');

    const { names, groceryEditors } = await readMembersWithGrants(linked.home);
    const addedBy = groceryAdderNamed(groceryEditors, names, input.by);
    const pick =
      input.product === null
        ? null
        : { ...frameProductMatch(input.product, addedBy), pickedAt: FieldValue.serverTimestamp() };

    const list = linked.home.collection(GROCERY_ITEMS);
    const ref =
      input.requestId === null
        ? list.doc()
        : list.doc(frameGroceryId(linked.frameId, input.requestId));
    return store.runTransaction(async (transaction): Promise<AddFrameGroceryItemResult> => {
      if ((await transaction.get(ref)).exists) return { status: 'linked', added: true };
      const unbought = await transaction.get(
        list.where('boughtBy', '==', null).limit(FRAME_UNBOUGHT_READ_LIMIT),
      );
      const items = unbought.docs.flatMap((doc) => {
        const item = parsed(unboughtShape, doc.data());
        return item === null ? [] : [{ ...item, id: doc.id }];
      });
      const existing = sameItemOnList(input.name, items);
      if (existing !== null) {
        const item = items.find((candidate) => candidate.id === existing);
        if (pick !== null && (item?.productMatch ?? null) === null) {
          transaction.update(list.doc(existing), { productMatch: pick });
        }
        return { status: 'linked', added: false, alreadyOnList: true };
      }
      transaction.create(ref, {
        ...frameGroceryItemDocument(input, addedBy),
        addedAt: FieldValue.serverTimestamp(),
        ...(pick === null ? {} : { productMatch: pick }),
      });
      return { status: 'linked', added: true };
    });
  },
);
