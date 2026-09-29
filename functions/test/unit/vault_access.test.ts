import { describe, expect, it } from 'vitest';

import { TICKET_LIFETIME_MS, mayOpenVault } from '../../src/documents/vault_access';
import { openingId } from '../../src/documents/vault_refs';

/**
 * Documents ADR-0002's access table, row by row, for the one decision that
 * issues a ticket to the bytes. The same table is in `firestore.rules`; this is
 * the copy that must not be more generous than it.
 */
const EMMA = 'm-emma';

describe('who may open a personal vault', () => {
  it('its owner', () => {
    expect(mayOpenVault({ role: 'member', viewerMemberId: EMMA, hasGrant: false }, EMMA)).toBe(
      true,
    );
  });

  it('a helper who owns it, like anybody else who owns theirs', () => {
    expect(mayOpenVault({ role: 'helper', viewerMemberId: EMMA, hasGrant: false }, EMMA)).toBe(
      true,
    );
  });

  it('an admin, for every vault — a child has no account to open their own', () => {
    expect(mayOpenVault({ role: 'admin', viewerMemberId: 'm-sam', hasGrant: false }, EMMA)).toBe(
      true,
    );
    expect(mayOpenVault({ role: 'admin', viewerMemberId: undefined, hasGrant: false }, EMMA)).toBe(
      true,
    );
  });

  it('a member or a helper somebody granted it to', () => {
    expect(mayOpenVault({ role: 'helper', viewerMemberId: 'm-thandi', hasGrant: true }, EMMA)).toBe(
      true,
    );
    expect(mayOpenVault({ role: 'member', viewerMemberId: 'm-alex', hasGrant: true }, EMMA)).toBe(
      true,
    );
  });

  it('and nobody else — a helper sees no ID copy unless granted it', () => {
    expect(
      mayOpenVault({ role: 'helper', viewerMemberId: 'm-thandi', hasGrant: false }, EMMA),
    ).toBe(false);
    expect(mayOpenVault({ role: 'member', viewerMemberId: 'm-alex', hasGrant: false }, EMMA)).toBe(
      false,
    );
  });

  it('a caller with no profile of their own is not mistaken for an unclaimed owner', () => {
    expect(mayOpenVault({ role: 'member', viewerMemberId: undefined, hasGrant: false }, EMMA)).toBe(
      false,
    );
  });
});

describe('the opening ticket', () => {
  it('lasts five minutes — enough to download, short enough to outlive a revoke briefly', () => {
    expect(TICKET_LIFETIME_MS).toBe(5 * 60 * 1000);
  });

  it('is addressed by the caller and the document, the way storage.rules looks it up', () => {
    expect(openingId('uid-sam', 'doc-1')).toBe('uid-sam_doc-1');
  });
});
