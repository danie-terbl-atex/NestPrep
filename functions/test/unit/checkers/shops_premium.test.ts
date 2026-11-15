import { Timestamp, type Firestore } from 'firebase-admin/firestore';
import { HttpsError } from 'firebase-functions/v2/https';
import { describe, expect, it } from 'vitest';

import {
  requireShopsPremium,
  requireShopsPremiumForMember,
} from '../../../src/checkers/shops_premium';

const NOW = new Date('2026-11-15T08:00:00Z');
const LATER = Timestamp.fromDate(new Date('2026-12-15T08:00:00Z'));
const EARLIER = Timestamp.fromDate(new Date('2026-10-15T08:00:00Z'));

type Documents = Record<string, Record<string, unknown>>;

interface Snapshot {
  exists: boolean;
  data: () => Record<string, unknown> | undefined;
  get: (field: string) => unknown;
}

interface Ref {
  path: string;
  collection: (name: string) => { doc: (id: string) => Ref };
  get: () => Promise<Snapshot>;
}

function storeOf(documents: Documents): Firestore {
  const snapshot = (path: string): Snapshot => ({
    exists: path in documents,
    data: (): Record<string, unknown> | undefined => documents[path],
    get: (field: string): unknown => documents[path]?.[field],
  });
  const ref = (path: string): Ref => ({
    path,
    collection: (name: string): { doc: (id: string) => Ref } => ({
      doc: (id: string): Ref => ref(`${path}/${name}/${id}`),
    }),
    get: (): Promise<Snapshot> => Promise.resolve(snapshot(path)),
  });
  return {
    collection: (name: string): { doc: (id: string) => Ref } => ({
      doc: (id: string): Ref => ref(`${name}/${id}`),
    }),
    getAll: (...refs: Ref[]): Promise<Snapshot[]> =>
      Promise.resolve(refs.map(({ path }) => snapshot(path))),
  } as unknown as Firestore;
}

async function refusalOf(call: Promise<void>): Promise<unknown> {
  try {
    await call;
    return null;
  } catch (error) {
    return error instanceof HttpsError ? error.details : error;
  }
}

const SHOPS_REFUSAL = { reason: 'premiumRequired', feature: 'shops' };

describe('a shop call that names its household', () => {
  it('passes for a Premium household', async () => {
    const store = storeOf({ 'households/h1/entitlement/current': { premiumUntil: LATER } });
    expect(await refusalOf(requireShopsPremium(store, 'h1'))).toBeNull();
  });

  it('refuses a free household and a lapsed one, naming shops', async () => {
    const store = storeOf({ 'households/lapsed/entitlement/current': { premiumUntil: EARLIER } });
    expect(await refusalOf(requireShopsPremium(store, 'free'))).toEqual(SHOPS_REFUSAL);
    expect(await refusalOf(requireShopsPremium(store, 'lapsed'))).toEqual(SHOPS_REFUSAL);
  });
});

describe('linking a shop, which names no household', () => {
  it('passes when any household the member is in has Premium', async () => {
    const store = storeOf({
      'users/sam': { householdIds: ['free', 'h1'] },
      'households/h1/entitlement/current': { premiumUntil: LATER },
    });
    expect(await refusalOf(requireShopsPremiumForMember(store, 'sam', NOW))).toBeNull();
  });

  it('refuses when every household is free or lapsed', async () => {
    const store = storeOf({
      'users/sam': { householdIds: ['free', 'lapsed'] },
      'households/lapsed/entitlement/current': { premiumUntil: EARLIER },
    });
    expect(await refusalOf(requireShopsPremiumForMember(store, 'sam', NOW))).toEqual(SHOPS_REFUSAL);
  });

  it('refuses somebody in no household, and an account that does not exist', async () => {
    const store = storeOf({
      'users/alone': { householdIds: [] },
      'households/h1/entitlement/current': { premiumUntil: LATER },
    });
    expect(await refusalOf(requireShopsPremiumForMember(store, 'alone', NOW))).toEqual(
      SHOPS_REFUSAL,
    );
    expect(await refusalOf(requireShopsPremiumForMember(store, 'nobody', NOW))).toEqual(
      SHOPS_REFUSAL,
    );
  });

  it('does not take another household’s Premium', async () => {
    const store = storeOf({
      'users/sam': { householdIds: ['free'] },
      'households/h1/entitlement/current': { premiumUntil: LATER },
    });
    expect(await refusalOf(requireShopsPremiumForMember(store, 'sam', NOW))).toEqual(SHOPS_REFUSAL);
  });
});
