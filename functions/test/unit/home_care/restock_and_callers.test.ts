import { HttpsError } from 'firebase-functions/v2/https';
import { describe, expect, it } from 'vitest';

import { ROLE_DEFAULTS, uniformGrant } from '../../../src/household/access';
import { homeCareReaderFrom } from '../../../src/home_care/home_care_caller';
import { groceryLineId, normalisedName, restockFor } from '../../../src/home_care/restock_decision';

/**
 * When a product goes onto the grocery list (home-care ADR-0005), and who may
 * call a home-care callable (household ADR-0003) — both decided without an
 * emulator.
 */

const product = (stock?: string, by: string | null = 'm-thandi'): Record<string, unknown> => ({
  name: 'Jik',
  kind: 'bleach',
  ...(stock === undefined ? {} : { stock, stockChangedBy: by }),
});

describe('a product crossing into low', () => {
  it('goes on the list when it moves from full or half into low or out', () => {
    for (const before of ['full', 'half']) {
      for (const after of ['low', 'out']) {
        expect(restockFor(product(before), product(after)), `${before}→${after}`).toEqual({
          name: 'Jik',
          markedBy: 'm-thandi',
        });
      }
    }
  });

  it('goes on the list when a product from before the tracker is first marked low', () => {
    expect(restockFor(product(), product('low'))).not.toBeNull();
  });

  it('goes on the list when it is created already low', () => {
    expect(restockFor(undefined, product('out'))).not.toBeNull();
  });

  it('adds nothing moving between low and out — it is already on its way', () => {
    expect(restockFor(product('low'), product('out'))).toBeNull();
    expect(restockFor(product('out'), product('low'))).toBeNull();
  });

  it('adds nothing when it is restocked, renamed, or deleted', () => {
    expect(restockFor(product('low'), product('full'))).toBeNull();
    expect(restockFor(product('full'), { ...product('full'), name: 'Bleach' })).toBeNull();
    expect(restockFor(product('full'), undefined)).toBeNull();
  });

  it('adds nothing for a mark that names nobody, or a level it does not know', () => {
    expect(restockFor(product('full'), product('low', null))).toBeNull();
    expect(restockFor(product('full'), product('nearly'))).toBeNull();
  });
});

describe('the grocery line', () => {
  it('has one id per product, so adding it twice is one line', () => {
    expect(groceryLineId('jik')).toBe('homeCare-jik');
  });

  it('merges on groceries’ normalised name', () => {
    expect(normalisedName('  Jik   Bleach ')).toBe('jik bleach');
    expect(normalisedName('JIK')).toBe(normalisedName('jik'));
  });
});

describe('who may call home care', () => {
  const household = (role: string, access?: unknown): Record<string, unknown> => ({
    members: { 'uid-a': role },
    ...(access === undefined ? {} : { access: { 'uid-a': access } }),
  });

  const refusalOf = (run: () => unknown): string | undefined => {
    try {
      run();
      return undefined;
    } catch (error) {
      if (!(error instanceof HttpsError)) throw error;
      return (error.details as { reason?: string }).reason;
    }
  };

  it('lets family, and a helper with any home-care level, in', () => {
    expect(homeCareReaderFrom(household('admin'), 'uid-a').level).toBe('edit');
    expect(homeCareReaderFrom(household('member'), 'uid-a').level).toBe('edit');
    expect(homeCareReaderFrom(household('helper', ROLE_DEFAULTS.helper), 'uid-a').level).toBe(
      'own',
    );
    expect(homeCareReaderFrom(household('helper', uniformGrant('view')), 'uid-a').level).toBe(
      'view',
    );
    // A helper claimed before household ADR-0003 keeps `edit` everywhere.
    expect(homeCareReaderFrom(household('helper'), 'uid-a').level).toBe('edit');
  });

  it('refuses whoever home care is not open to', () => {
    expect(
      refusalOf(() => homeCareReaderFrom(household('carer', ROLE_DEFAULTS.carer), 'uid-a')),
    ).toBe('homeCareNotShared');
    expect(refusalOf(() => homeCareReaderFrom(household('kid', ROLE_DEFAULTS.kid), 'uid-a'))).toBe(
      'homeCareNotShared',
    );
  });

  it('refuses a stranger and a household it cannot read', () => {
    expect(refusalOf(() => homeCareReaderFrom(household('admin'), 'uid-b'))).toBe('notAMember');
    expect(refusalOf(() => homeCareReaderFrom({ members: 'nope' }, 'uid-a'))).toBe('notAMember');
  });
});
