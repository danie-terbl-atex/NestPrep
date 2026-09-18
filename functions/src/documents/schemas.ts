import { z } from 'zod';

/**
 * The documents callables' input, parsed at the edge and never cast (ENG-09,
 * BE-03). `syncDocumentAccess` has no schema because it has no input: its
 * subject is the caller, which is re-derived from the token and Firestore.
 */
export const deleteDocumentFolderInput = z.object({
  householdId: z.string().trim().min(1).max(64),
  folderId: z.string().trim().min(1).max(64),
});
export type DeleteDocumentFolderInput = z.infer<typeof deleteDocumentFolderInput>;
