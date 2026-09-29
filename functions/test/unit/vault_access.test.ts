import { readFileSync } from 'node:fs';
import { resolve } from 'node:path';

import { describe, expect, it } from 'vitest';

import { FAMILY_ROLES, TICKET_LIFETIME_MS, mayOpenVault } from '../../src/documents/vault_access';
import { openingId } from '../../src/documents/vault_refs';

/**
 * Documents ADR-0002's access table, row by row, for the one decision that
 * issues a ticket to the bytes. The same table is in `firestore.rules` and
 * `storage.rules`; this is the copy that must not be more generous than them.
 */
const EMMA = 'm-emma';

describe('who may open a personal vault', () => {
  it('its owner, whatever their role — a helper owns her own ID copy', () => {
    for (const role of ['helper', 'kid', 'carer']) {
      expect(mayOpenVault({ role, viewerMemberId: EMMA, hasGrant: false }, EMMA), role).toBe(true);
    }
  });

  it('the family, for every vault — per-item privacy between family is out of v1', () => {
    for (const role of ['admin', 'parent', 'member']) {
      expect(mayOpenVault({ role, viewerMemberId: 'm-sam', hasGrant: false }, EMMA), role).toBe(
        true,
      );
    }
    expect(mayOpenVault({ role: 'admin', viewerMemberId: undefined, hasGrant: false }, EMMA)).toBe(
      true,
    );
  });

  it('anybody else only once somebody granted it', () => {
    for (const role of ['helper', 'kid', 'carer']) {
      expect(mayOpenVault({ role, viewerMemberId: 'm-other', hasGrant: true }, EMMA), role).toBe(
        true,
      );
    }
  });

  it('and nobody else — a helper sees no ID copy unless granted it', () => {
    for (const role of ['helper', 'kid', 'carer']) {
      expect(mayOpenVault({ role, viewerMemberId: 'm-other', hasGrant: false }, EMMA), role).toBe(
        false,
      );
    }
  });

  it('a caller with no profile of their own is not mistaken for an unclaimed owner', () => {
    expect(mayOpenVault({ role: 'helper', viewerMemberId: undefined, hasGrant: false }, EMMA)).toBe(
      false,
    );
  });
});

describe('family means the same thing in all three places that decide it', () => {
  const repoRoot = resolve(import.meta.dirname, '../../..');
  const list = `[${FAMILY_ROLES.map((role) => `'${role}'`).join(', ')}]`;

  it('firestore.rules names the same roles', () => {
    expect(readFileSync(resolve(repoRoot, 'firestore.rules'), 'utf8')).toContain(`in ${list}`);
  });

  it('storage.rules names the same roles', () => {
    expect(readFileSync(resolve(repoRoot, 'storage.rules'), 'utf8')).toContain(`in ${list}`);
  });
});

describe('the opening ticket', () => {
  it('lasts five minutes — enough to download, short enough to outlive a revoke briefly', () => {
    expect(TICKET_LIFETIME_MS).toBe(5 * 60 * 1000);
  });

  it('is addressed by the caller and the document, the way storage.rules looks it up', () => {
    expect(openingId('uid-sam', 'doc-1')).toBe('uid-sam_doc-1');
    expect(readFileSync(resolve(import.meta.dirname, '../../../storage.rules'), 'utf8')).toContain(
      "request.auth.uid + '_' + documentId",
    );
  });
});
