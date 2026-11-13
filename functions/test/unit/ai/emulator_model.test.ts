import type { Firestore } from 'firebase-admin/firestore';
import { describe, expect, it } from 'vitest';

import { EmulatorModel, LIVE_FEATURES } from '../../../src/ai/emulator_model';
import type { ModelRequest } from '../../../src/ai/generative_model';
import { FakeModel } from './fakes';

const storeHolding = (documents: Record<string, Record<string, unknown>>): Firestore =>
  ({
    collection: () => ({
      doc: (feature: string) => ({
        get: () =>
          Promise.resolve({
            data: () => documents[feature],
            get: (field: string) => documents[feature]?.[field],
          }),
      }),
    }),
  }) as unknown as Firestore;

const asking = (feature: string): ModelRequest => ({
  system: 's',
  parts: [],
  responseSchema: { type: 'OBJECT', properties: {} },
  maxOutputTokens: 1,
  temperature: 0,
  labels: { feature },
});

async function answerFor(
  feature: string,
  document: Record<string, unknown> | undefined,
): Promise<{ text: string; liveCalls: number }> {
  const live = new FakeModel(['{"from":"live"}']);
  const model = new EmulatorModel(
    storeHolding(document === undefined ? {} : { [feature]: document }),
    () => live,
  );
  const { text } = await model.generate(asking(feature), new AbortController().signal);
  return { text, liveCalls: live.calls };
}

const CANNED = { reply: '{"from":"canned"}' };

describe('the emulator’s model', () => {
  it('names recipe import as the one feature that may go live', () => {
    expect(LIVE_FEATURES).toEqual(['recipeImport', 'recipeDocument']);
  });

  it('asks the real model for recipe import with live: true', async () => {
    expect(await answerFor('recipeImport', { ...CANNED, live: true })).toEqual({
      text: '{"from":"live"}',
      liveCalls: 1,
    });
  });

  it('stays canned when the field is absent, false or not a boolean', async () => {
    for (const document of [CANNED, { ...CANNED, live: false }, { ...CANNED, live: 'true' }]) {
      expect(await answerFor('recipeImport', document)).toEqual({
        text: CANNED.reply,
        liveCalls: 0,
      });
    }
  });

  it('stays canned for every other feature, even with live: true', async () => {
    for (const feature of ['listScan', 'schoolLetter', 'lunchIdeas', 'lunchWeek', 'unknown']) {
      expect(await answerFor(feature, { ...CANNED, live: true })).toEqual({
        text: CANNED.reply,
        liveCalls: 0,
      });
    }
  });

  it('answers an empty object for a document nobody wrote', async () => {
    expect(await answerFor('recipeImport', undefined)).toEqual({ text: '{}', liveCalls: 0 });
  });
});

describe('a canned cycle', () => {
  function cyclingStore(document: Record<string, unknown>): Firestore {
    const snapshot = (): unknown => ({
      data: () => document,
      get: (field: string) => document[field],
    });
    const ref = { get: (): Promise<unknown> => Promise.resolve(snapshot()) };
    return {
      collection: () => ({ doc: () => ref }),
      runTransaction: (work: (transaction: unknown) => Promise<unknown>) =>
        work({
          get: () => Promise.resolve(snapshot()),
          update: (_ref: unknown, fields: Record<string, unknown>) =>
            Object.assign(document, fields),
        }),
    } as unknown as Firestore;
  }

  it('answers its replies in turn, round and round', async () => {
    const model = new EmulatorModel(
      cyclingStore({ cycle: ['{"kind":"creature"}', '{"kind":"person"}'] }),
      () => new FakeModel([]),
    );
    const texts: string[] = [];
    for (let turn = 0; turn < 3; turn += 1) {
      texts.push(
        (await model.generate(asking('avatarDrawingCheck'), new AbortController().signal)).text,
      );
    }
    expect(texts).toEqual(['{"kind":"creature"}', '{"kind":"person"}', '{"kind":"creature"}']);
  });
});
