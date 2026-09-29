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

/**
 * Opening one vault document (documents ADR-0003). The owner is part of the
 * address, because a vault is a path and not a field (documents ADR-0002).
 */
export const openVaultDocumentInput = z.object({
  householdId: z.string().trim().min(1).max(64),
  ownerMemberId: z.string().trim().min(1).max(64),
  documentId: z.string().trim().min(1).max(64),
});
export type OpenVaultDocumentInput = z.infer<typeof openVaultDocumentInput>;
