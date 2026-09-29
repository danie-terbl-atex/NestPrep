import { describe, expect, it } from 'vitest';

import {
  AREAS,
  AREA_LEVELS,
  ROLE_DEFAULTS,
  STORAGE_AREAS,
  effectiveGrant,
  isFamilyRole,
  readGrant,
  storageGrant,
  uniformGrant,
} from '../../src/household/access';

/**
 * The per-area grant (household ADR-0003) as pure functions. The rules suite
 * proves what the rules do with a grant; this proves which grant a household
 * records in the first place.
 */
describe('who is family', () => {
  it('is an admin, a parent, and the old `member` that means a parent', () => {
    expect(['admin', 'parent', 'member'].filter(isFamilyRole)).toHaveLength(3);
  });

  it('is never a kid, a helper or a carer', () => {
    expect(['kid', 'helper', 'carer'].some(isFamilyRole)).toBe(false);
  });
});

describe('the grant a claim records', () => {
  it('is none for family, who need none', () => {
    expect(effectiveGrant('admin', { documents: 'none' })).toBeNull();
    expect(effectiveGrant('parent', undefined)).toBeNull();
    expect(effectiveGrant('member', undefined)).toBeNull();
  });

  it("is the role's defaults when the profile holds no choice", () => {
    expect(effectiveGrant('helper', undefined)).toEqual(ROLE_DEFAULTS.helper);
    expect(effectiveGrant('kid', null)).toEqual(ROLE_DEFAULTS.kid);
    expect(effectiveGrant('carer', undefined)).toEqual(ROLE_DEFAULTS.carer);
  });

  it("is the parent's choice when there is one", () => {
    const cleaningOnly = { ...uniformGrant('none'), homeCare: 'own' };
    expect(effectiveGrant('helper', cleaningOnly)).toEqual(cleaningOnly);
  });
});

describe('a stored grant, read', () => {
  it('fills an area it does not mention with none', () => {
    expect(readGrant({ calendar: 'view' })).toEqual({ ...uniformGrant('none'), calendar: 'view' });
  });

  it('narrows a level the area does not accept to none, never widens it', () => {
    expect(readGrant({ groceries: 'own' })?.groceries).toBe('none');
    expect(readGrant({ calendar: 'superuser' })?.calendar).toBe('none');
  });

  it('drops an area nobody has heard of', () => {
    expect(Object.keys(readGrant({ garage: 'edit' }) ?? {})).toEqual([...AREAS]);
  });

  it('is absent when nothing grant-shaped is stored', () => {
    expect(readGrant(undefined)).toBeNull();
    expect(readGrant('edit')).toBeNull();
    expect(readGrant(['edit'])).toBeNull();
  });
});

describe('what travels to Storage on the token', () => {
  it('is only the areas that keep bytes, and only where there is access', () => {
    expect(storageGrant(ROLE_DEFAULTS.carer)).toEqual({
      nannyHub: 'edit',
      familyProfiles: 'view',
      medical: 'view',
    });
    expect(storageGrant(uniformGrant('none'))).toEqual({});
  });

  it('never carries an area whose bytes are not in Storage', () => {
    for (const area of Object.keys(storageGrant(uniformGrant('edit')))) {
      expect(STORAGE_AREAS).toContain(area);
    }
  });
});

describe('the role defaults', () => {
  it('only ever use a level their area accepts', () => {
    for (const grant of Object.values(ROLE_DEFAULTS)) {
      for (const area of AREAS) {
        expect(AREA_LEVELS[area]).toContain(grant[area]);
      }
    }
  });

  it('show no kid, helper or carer the documents until a parent says so', () => {
    for (const grant of Object.values(ROLE_DEFAULTS)) {
      expect(grant.documents).toBe('none');
    }
  });

  it('show a helper no medical detail, and a carer the medical detail they need', () => {
    expect(ROLE_DEFAULTS.helper.medical).toBe('none');
    expect(ROLE_DEFAULTS.carer.medical).toBe('view');
  });
});
