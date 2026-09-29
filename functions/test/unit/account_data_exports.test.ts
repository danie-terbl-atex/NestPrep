import { readFileSync, readdirSync } from 'node:fs';
import { resolve } from 'node:path';

import { GeoPoint, Timestamp } from 'firebase-admin/firestore';
import { describe, expect, it } from 'vitest';

import { AUTHORED_RECORDS } from '../../src/account_data/authored_records';
import {
  EXPORT_LIFETIME_MS,
  exportPath,
  sweepExpiredExports,
} from '../../src/account_data/export_files';
import { plainDocument, plainValue } from '../../src/account_data/plain_value';
import { MEMBER_LOCATIONS, NANNY_CHILD_CARDS } from '../../src/account_data/personal_refs';
import { accountDeletionRequestInput, deleteAccountInput } from '../../src/account_data/schemas';
import { type ObjectStore, bucketName } from '../../src/shared/storage';

/**
 * Download my data and what it is built from (accounts ADR-0006): the values
 * an export writes, the hour its link lives, the sweep that removes it, and
 * the inventory of what counts as a person's — checked against the rules, so
 * a feature that adds a collection stamped with its author cannot be left out
 * of everybody's export by accident.
 */

const repoRoot = resolve(import.meta.dirname, '../../..');

describe('plainValue — what an export writes', () => {
  it('writes instants as ISO-8601 in UTC (ENG-21)', () => {
    const instant = Timestamp.fromDate(new Date(Date.UTC(2026, 8, 29, 6, 30)));
    expect(plainValue({ at: instant })).toEqual({ at: '2026-09-29T06:30:00.000Z' });
  });

  it('writes a position as latitude and longitude', () => {
    expect(plainValue(new GeoPoint(-33.9, 18.4))).toEqual({ latitude: -33.9, longitude: 18.4 });
  });

  it('keeps nested lists and maps, sorted by key so two exports compare line by line', () => {
    expect(plainValue({ b: [1, { d: true, c: null }], a: 'x' })).toEqual({
      a: 'x',
      b: [1, { c: null, d: true }],
    });
    expect(Object.keys(plainValue({ b: 1, a: 2 }) as object)).toEqual(['a', 'b']);
  });

  it('shows a kind of value it does not know by name rather than dropping it', () => {
    expect(plainValue(() => 1)).toBe('[function]');
  });

  it('puts the document id beside its fields, and says null for a document that is not there', () => {
    expect(plainDocument('m-sam', { displayName: 'Sam' })).toEqual({
      id: 'm-sam',
      displayName: 'Sam',
    });
    expect(plainDocument('m-sam', undefined)).toBeNull();
  });
});

describe('the export link lives an hour, and no longer', () => {
  it('matches the Storage rule that serves it', () => {
    const rule = readFileSync(
      resolve(repoRoot, 'rules/storage/paths/account_exports.rules'),
      'utf8',
    );
    expect(rule).toContain("duration.value(1, 'h')");
    expect(EXPORT_LIFETIME_MS).toBe(60 * 60 * 1000);
  });

  it('is written under the account’s own prefix, the path the rule keys on', () => {
    expect(exportPath('uid-sam', 'e1')).toBe('accountExports/uid-sam/e1.json');
  });

  it('the sweep removes only exports older than the hour', async () => {
    const created: Record<string, Date> = {
      'accountExports/a/old.json': new Date(Date.UTC(2026, 8, 29, 6, 0)),
      'accountExports/b/fresh.json': new Date(Date.UTC(2026, 8, 29, 7, 45)),
    };
    const deleted: string[] = [];
    const objects: ObjectStore = {
      deletePrefix: () => Promise.resolve(),
      save: () => Promise.resolve(),
      listCreatedBefore: (prefix, before) =>
        Promise.resolve(
          Object.entries(created)
            .filter(([path, at]) => path.startsWith(prefix) && at < before)
            .map(([path]) => path),
        ),
      deleteObjects: (paths) => {
        deleted.push(...paths);
        return Promise.resolve();
      },
    };
    const removed = await sweepExpiredExports(objects, new Date(Date.UTC(2026, 8, 29, 8, 0)));
    expect(removed).toBe(1);
    expect(deleted).toEqual(['accountExports/a/old.json']);
  });
});

describe('the default bucket', () => {
  it('is the one FIREBASE_CONFIG names', () => {
    expect(bucketName({ FIREBASE_CONFIG: '{"storageBucket":"b.example"}' })).toBe('b.example');
  });

  it('falls back to the project’s firebasestorage.app bucket', () => {
    expect(bucketName({ GCLOUD_PROJECT: 'p1' })).toBe('p1.firebasestorage.app');
  });
});

describe('the inventory of what is a person’s', () => {
  const partials = readdirSync(resolve(repoRoot, 'rules/firestore/household'))
    .filter((name) => name.endsWith('.rules'))
    .map((name) => readFileSync(resolve(repoRoot, 'rules/firestore/household', name), 'utf8'))
    .join('\n');

  /** Every `collection → field` a rule stamps with `isOwnMember(…, request.resource.data.<field>)`. */
  function stampedAuthorship(): string[] {
    const found = new Set<string>();
    let collection = '';
    for (const line of partials.split('\n')) {
      const match = /match \/(\w+)\/\{/.exec(line);
      if (match?.[1] !== undefined) collection = match[1];
      const stamp = /isOwnMember\(householdId, request\.resource\.data\.(\w+)\)/.exec(line);
      if (stamp?.[1] !== undefined) found.add(`${collection}.${stamp[1]}`);
    }
    return [...found].sort();
  }

  // Stamped, but not "what the person put into the household". A vault's own
  // rows are exported with the vault, and a grant names who granted it, which
  // the owner's export shows. The rest record somebody *doing* something to a
  // record that is already listed — ticking, buying, skipping, updating,
  // starting a shift — or live under a parent the export already walks.
  const COVERED_ELSEWHERE = [
    'grants.grantedBy',
    'vaultDocuments.uploadedBy',
    'lunchPrep.addedBy',
    'taskCompletions.completedBy',
    'groceryItems.boughtBy',
    'eventExceptions.skippedBy',
    'nannyChecklists.updatedBy',
    'nannyChildCards.updatedBy',
    'nannyHome.updatedBy',
    'nannyShifts.startedBy',
    'homeCareJobs.by',
    'entries.byMemberId',
    'rewardRequests.memberId',
  ];

  it('lists every collection whose rules stamp who made a record', () => {
    const listed = AUTHORED_RECORDS.map((record) => `${record.collection}.${record.authorField}`);
    const missing = stampedAuthorship().filter(
      (stamp) => !listed.includes(stamp) && !COVERED_ELSEWHERE.includes(stamp),
    );
    expect(missing, 'add it to AUTHORED_RECORDS so it is in the export').toEqual([]);
  });

  it('names only collections the rules actually have', () => {
    for (const { collection } of AUTHORED_RECORDS) {
      expect(partials, collection).toContain(`match /${collection}/{`);
    }
    for (const collection of [
      MEMBER_LOCATIONS,
      NANNY_CHILD_CARDS,
      'familyProfiles',
      'memberHealth',
    ]) {
      expect(partials, collection).toContain(`match /${collection}/{`);
    }
  });
});

describe('the account-data inputs', () => {
  it('deleteAccount takes the confirmation and the agreed endings, and nothing else', () => {
    expect(
      deleteAccountInput.safeParse({ confirmation: 'DELETE', endingHouseholdIds: [] }).success,
    ).toBe(true);
    expect(deleteAccountInput.safeParse({ confirmation: 'DELETE' }).success).toBe(false);
    expect(
      deleteAccountInput.safeParse({ confirmation: 'DELETE', endingHouseholdIds: [], uid: 'x' })
        .success,
    ).toBe(false);
  });

  it('the web request takes an address and an optional message, lower-cased and bounded', () => {
    const parsed = accountDeletionRequestInput.safeParse({ email: ' Sam@Example.COM ' });
    expect(parsed.success && parsed.data.email).toBe('sam@example.com');
    expect(accountDeletionRequestInput.safeParse({ email: 'not an address' }).success).toBe(false);
    expect(
      accountDeletionRequestInput.safeParse({ email: 'a@b.co', message: 'x'.repeat(1001) }).success,
    ).toBe(false);
    expect(
      accountDeletionRequestInput.safeParse({ email: 'a@b.co', website: 'spam' }).success,
    ).toBe(false);
  });
});
