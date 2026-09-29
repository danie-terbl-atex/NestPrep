// Imported first, and deliberately: it calls `setGlobalOptions`, and ES modules
// evaluate imports in declaration order, before any statement in this file's
// body. Every export below builds its `onCall` endpoint at import time, so the
// options have to be set by a module that is evaluated ahead of them — a call
// at the foot of this file sets nothing at all. See `shared/global_options.ts`.
import './shared/global_options';

export { createHousehold } from './household/create_household';
export { createInvite } from './household/create_invite';
export { redeemInvite } from './household/redeem_invite';
export { leaveHousehold } from './household/leave_household';
export { removeMember } from './household/remove_member';
export { setMemberRole } from './household/set_member_role';
export { syncDocumentAccess } from './documents/sync_document_access';
export { deleteDocumentFolder } from './documents/delete_document_folder';
// documents phase 2 — personal vaults and expiry reminders (documents ADR-0003, ADR-0005)
export { openVaultDocument } from './documents/open_vault_document';
export { sweepExpiryReminders } from './documents/sweep_expiry_reminders';
