import { isFamilyRole } from '../household/access';

export interface VaultCaller {
  /** The caller's role in the household, re-derived from the membership map. */
  readonly role: string;
  /** The profile the caller claimed here, if they claimed one. */
  readonly viewerMemberId: string | undefined;
  /** Whether a grant addressed to the caller exists on this vault. */
  readonly hasGrant: boolean;
}

/**
 * Who may open a personal vault (documents ADR-0002), as one decision with no
 * I/O, so every row of the ADR's table is a unit test rather than an emulator
 * run.
 *
 * The same table is in `firestore.rules` for the metadata. This copy exists
 * because the bytes are read through a ticket only this Function writes, and
 * the ticket must not be issued to anybody the rules would refuse.
 */
export function mayOpenVault(caller: VaultCaller, ownerMemberId: string): boolean {
  // Family reads and manages every vault: household ADR-0003 keeps per-item
  // privacy between family members out of v1 (`isFamilyRole`, one list).
  if (isFamilyRole(caller.role)) return true;
  if (caller.viewerMemberId !== undefined && caller.viewerMemberId === ownerMemberId) return true;
  return caller.hasGrant;
}

/**
 * How long a ticket lets its holder read the bytes. Long enough to download 20
 * MiB on a slow connection; short enough that a revoked grant stops mattering
 * within minutes (documents ADR-0003).
 */
export const TICKET_LIFETIME_MS = 5 * 60 * 1000;
