import { Timestamp, type Firestore } from 'firebase-admin/firestore';
import { HttpsError, type CallableRequest } from 'firebase-functions/v2/https';
import { beforeEach, describe, expect, it, vi } from 'vitest';

import { translateHomeCareTexts } from '../../src/home_care/translate_home_care_texts';
import { translationId } from '../../src/home_care/translation_id';
import { setCarerShiftOnly } from '../../src/nanny_hub/set_carer_shift_only';

/**
 * The nanny hub's and home care's callables in a household without Premium
 * (subscriptions ADR-0008, ADR-0009): refused as `premiumRequired`, naming the
 * area, after the caller's own checks and before anything is read or written.
 */

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

interface Fake {
  documents: Record<string, Record<string, unknown>>;
  updated: string[];
  cacheReads: number;
}

const fake = vi.hoisted((): Fake => ({ documents: {}, updated: [], cacheReads: 0 }));

function fakeStore(): Firestore {
  const snapshot = (path: string): Snapshot => ({
    exists: path in fake.documents,
    data: (): Record<string, unknown> | undefined => fake.documents[path],
    get: (field: string): unknown => fake.documents[path]?.[field],
  });
  const ref = (path: string): Ref => ({
    path,
    collection: (name: string): { doc: (id: string) => Ref } => ({
      doc: (id: string): Ref => ref(`${path}/${name}/${id}`),
    }),
    get: (): Promise<Snapshot> => Promise.resolve(snapshot(path)),
  });
  const transaction = {
    get: (target: Ref): Promise<Snapshot> => target.get(),
    update: (target: Ref): void => {
      fake.updated.push(target.path);
    },
  };
  return {
    collection: (name: string): { doc: (id: string) => Ref } => ({
      doc: (id: string): Ref => ref(`${name}/${id}`),
    }),
    getAll: (...refs: Ref[]): Promise<Snapshot[]> => {
      fake.cacheReads += 1;
      return Promise.resolve(refs.map(({ path }) => snapshot(path)));
    },
    runTransaction: <T>(body: (given: typeof transaction) => Promise<T>): Promise<T> =>
      body(transaction),
  } as unknown as Firestore;
}

vi.mock('../../src/shared/firestore', () => ({ db: (): Firestore => fakeStore() }));

const DAY = 86_400_000;
const PREMIUM = { premiumUntil: Timestamp.fromMillis(Date.now() + DAY) };
const LAPSED = { premiumUntil: Timestamp.fromMillis(Date.now() - DAY) };
const HOME = 'households/h1';
const ENTITLEMENT = `${HOME}/entitlement/current`;

function request<T>(uid: string, data: T): CallableRequest<T> {
  return { auth: { uid }, data } as unknown as CallableRequest<T>;
}

async function refusalOf(call: Promise<unknown>): Promise<unknown> {
  try {
    await call;
    return null;
  } catch (error) {
    return error instanceof HttpsError ? error.details : error;
  }
}

beforeEach(() => {
  fake.updated = [];
  fake.cacheReads = 0;
  fake.documents = {
    [HOME]: {
      name: 'The Parkers',
      members: { 'uid-sam': 'admin', 'uid-thandi': 'helper', 'uid-nomsa': 'carer' },
      profiles: { 'uid-sam': 'm-sam', 'uid-thandi': 'm-thandi', 'uid-nomsa': 'm-nomsa' },
    },
    [`${HOME}/members/m-nomsa`]: { role: 'carer' },
    'appConfig/flags': { homeCareHelperLanguage: true },
  };
});

describe('setCarerShiftOnly and Premium', () => {
  const mark = (uid: string, shiftOnly: boolean): Promise<unknown> =>
    Promise.resolve(
      setCarerShiftOnly.run(request(uid, { householdId: 'h1', memberId: 'm-nomsa', shiftOnly })),
    );

  it('marks a carer in a Premium household', async () => {
    fake.documents[ENTITLEMENT] = PREMIUM;
    expect(await mark('uid-sam', true)).toEqual({
      householdId: 'h1',
      memberId: 'm-nomsa',
      shiftOnly: true,
    });
    expect(fake.updated).toEqual([HOME]);
  });

  it('refuses marking in a free household and a lapsed one, and writes nothing', async () => {
    const refusal = { reason: 'premiumRequired', feature: 'nannyHub' };
    expect(await refusalOf(mark('uid-sam', true))).toEqual(refusal);
    fake.documents[ENTITLEMENT] = LAPSED;
    expect(await refusalOf(mark('uid-sam', true))).toEqual(refusal);
    expect(fake.updated).toEqual([]);
  });

  it('still lifts a mark without Premium, so a carer is never locked out for good', async () => {
    expect(await mark('uid-sam', false)).toMatchObject({ shiftOnly: false });
    expect(fake.updated).toEqual([HOME]);
  });

  it('says who the caller is before it says Premium', async () => {
    expect(await refusalOf(mark('uid-nomsa', true))).toMatchObject({ reason: 'notAnAdmin' });
  });
});

describe('translateHomeCareTexts and Premium', () => {
  const translate = (uid: string): Promise<unknown> =>
    Promise.resolve(
      translateHomeCareTexts.run(
        request(uid, { householdId: 'h1', language: 'zu' as const, texts: ['Open a window'] }),
      ),
    );

  it('answers a Premium household, here from what it translated before', async () => {
    fake.documents[ENTITLEMENT] = PREMIUM;
    fake.documents[`${HOME}/homeCareTranslations/${translationId('Open a window', 'zu')}`] = {
      text: 'Vula ifasitela',
    };
    expect(await translate('uid-thandi')).toEqual({
      translations: [{ text: 'Open a window', translated: 'Vula ifasitela' }],
    });
  });

  it('refuses a free household and a lapsed one before the cache is read', async () => {
    const refusal = { reason: 'premiumRequired', feature: 'homeCare' };
    expect(await refusalOf(translate('uid-thandi'))).toEqual(refusal);
    fake.documents[ENTITLEMENT] = LAPSED;
    expect(await refusalOf(translate('uid-sam'))).toEqual(refusal);
    expect(fake.cacheReads).toBe(0);
  });

  it('says the grant and the switch before it says Premium', async () => {
    expect(await refusalOf(translate('uid-nomsa'))).toMatchObject({ reason: 'homeCareNotShared' });
    fake.documents['appConfig/flags'] = {};
    expect(await refusalOf(translate('uid-thandi'))).toMatchObject({
      reason: 'translationSwitchedOff',
    });
  });
});
