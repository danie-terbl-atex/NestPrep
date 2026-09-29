import { describe, expect, it } from 'vitest';

import { EmulatorTranslator } from '../../../src/home_care/emulator_translator';
import { HttpUnreachable, type HttpClient } from '../../../src/shared/http_client';
import {
  CloudTranslator,
  isWorthRetrying,
  outcomeOf,
  type TranslationToken,
} from '../../../src/home_care/cloud_translator';
import {
  FREE_MONTHLY_CHARACTERS,
  PREMIUM_MONTHLY_CHARACTERS,
  charactersOf,
  monthKey,
  monthlyAllowance,
  refunded,
  spendWithin,
} from '../../../src/home_care/translation_cap';
import { translationId } from '../../../src/home_care/translation_id';

/**
 * The helper's language, as the server sees it (home-care ADR-0006): the
 * cache id both sides compute, the month's cap, and Google's answers read as
 * one of three outcomes — against canned replies, never the network (BE-09).
 */

describe('the id a translation is cached under', () => {
  // The same vectors are in `helper_language_test.dart`: the phone
  // reads the cache by this id before it asks, so the two must agree.
  it('is the SHA-256 of the text and the language', () => {
    expect(translationId('Open a window', 'zu')).toBe(
      '447f9a95bdd5f7621df94b927415e328c7d53d413598ecbb61fb42f1512ed6bf_zu',
    );
    expect(translationId('Wipe the counters', 'nso')).toBe(
      '54950ce4a5d51481c2aebc88e60e9a1bf0ea25e35b6a9e3fb9433b63e141a88c_nso',
    );
    expect(translationId('Vula ifasitela — ngokushesha', 'xh')).toBe(
      '773368141dd3ef30d74e9eadab960bf5b199df5f3d3ac82ec1e0866ea4ad007d_xh',
    );
  });

  it('differs for a text that differs by a letter, and by language', () => {
    expect(translationId('Open a window', 'zu')).not.toBe(translationId('Open a Window', 'zu'));
    expect(translationId('Open a window', 'zu')).not.toBe(translationId('Open a window', 'xh'));
  });
});

describe('the month’s cap', () => {
  it('is counted in the UTC calendar month', () => {
    expect(monthKey(new Date('2026-09-30T23:59:59Z'))).toBe('2026-09');
    expect(monthKey(new Date('2026-10-01T00:00:00Z'))).toBe('2026-10');
  });

  it('is ten times larger on premium', () => {
    expect(monthlyAllowance(false)).toBe(FREE_MONTHLY_CHARACTERS);
    expect(monthlyAllowance(true)).toBe(PREMIUM_MONTHLY_CHARACTERS);
    expect(PREMIUM_MONTHLY_CHARACTERS).toBe(FREE_MONTHLY_CHARACTERS * 10);
  });

  it('counts every character sent', () => {
    expect(charactersOf(['Open a window', 'Wipe'])).toBe(17);
    expect(charactersOf([])).toBe(0);
  });

  it('allows a spend up to the allowance and refuses one past it', () => {
    expect(spendWithin(19_990, 10, FREE_MONTHLY_CHARACTERS)).toBe(20_000);
    expect(spendWithin(19_991, 10, FREE_MONTHLY_CHARACTERS)).toBeNull();
    expect(spendWithin(undefined, 5, FREE_MONTHLY_CHARACTERS)).toBe(5);
  });

  it('reads a corrupt count as nothing spent rather than failing', () => {
    expect(spendWithin('lots', 5, 10)).toBe(5);
    expect(spendWithin(-40, 5, 10)).toBe(5);
    expect(spendWithin(Number.NaN, 5, 10)).toBe(5);
  });

  it('gives a refund back, never below nothing', () => {
    expect(refunded(120, 20)).toBe(100);
    expect(refunded(10, 20)).toBe(0);
    expect(refunded(undefined, 20)).toBe(0);
  });
});

describe('Google’s answer', () => {
  const reply = (texts: string[]): string =>
    JSON.stringify({ translations: texts.map((translatedText) => ({ translatedText })) });

  it('is the translations, in the order asked', () => {
    expect(outcomeOf(200, reply(['Vula', 'Sula']), 2)).toEqual({
      kind: 'translated',
      texts: ['Vula', 'Sula'],
    });
  });

  it('is unsupported when Google refuses the language', () => {
    expect(outcomeOf(400, '{"error":{"status":"INVALID_ARGUMENT"}}', 1)).toEqual({
      kind: 'unsupported',
    });
  });

  it('is unavailable when refused, failing, or unreadable', () => {
    expect(outcomeOf(403, '', 1)).toEqual({ kind: 'unavailable', reason: 'refused' });
    expect(outcomeOf(503, '', 1)).toEqual({ kind: 'unavailable', reason: 'status 503' });
    expect(outcomeOf(200, 'not json', 1)).toEqual({ kind: 'unavailable', reason: 'unreadable' });
    // One line back for two asked is not an answer to pair up.
    expect(outcomeOf(200, reply(['Vula']), 2)).toEqual({
      kind: 'unavailable',
      reason: 'unreadable',
    });
  });

  it('is worth one more try only when Google is busy, failing or unreachable', () => {
    expect(isWorthRetrying({ kind: 'unavailable', reason: 'status 429' })).toBe(true);
    expect(isWorthRetrying({ kind: 'unavailable', reason: 'status 502' })).toBe(true);
    expect(isWorthRetrying({ kind: 'unavailable', reason: 'network: TimeoutError' })).toBe(true);
    expect(isWorthRetrying({ kind: 'unavailable', reason: 'refused' })).toBe(false);
    expect(isWorthRetrying({ kind: 'unsupported' })).toBe(false);
    expect(isWorthRetrying({ kind: 'translated', texts: [] })).toBe(false);
  });
});

describe('the Cloud Translation adapter', () => {
  const token = (value: string | null): TranslationToken => ({
    token: () => Promise.resolve(value),
  });

  function answering(...answers: (() => { status: number; body: string })[]): {
    http: HttpClient;
    sent: { url: string; body: unknown }[];
  } {
    const sent: { url: string; body: unknown }[] = [];
    const http: HttpClient = {
      send(url, request) {
        sent.push({ url, body: JSON.parse(request.body ?? 'null') as unknown });
        const next = answers.shift();
        if (next === undefined) throw new Error('asked once too often');
        return Promise.resolve({ ...next(), location: null });
      },
    };
    return { http, sent };
  }

  it('asks the project’s global location, from English, for the target', async () => {
    const { http, sent } = answering(() => ({
      status: 200,
      body: JSON.stringify({ translations: [{ translatedText: 'Vula ifasitela' }] }),
    }));
    const outcome = await new CloudTranslator(http, token('t'), 'nestprep-643b7').translate(
      ['Open a window'],
      'zu',
    );
    expect(outcome).toEqual({ kind: 'translated', texts: ['Vula ifasitela'] });
    expect(sent[0]?.url).toBe(
      'https://translation.googleapis.com/v3/projects/nestprep-643b7/locations/global:translateText',
    );
    expect(sent[0]?.body).toEqual({
      contents: ['Open a window'],
      mimeType: 'text/plain',
      sourceLanguageCode: 'en',
      targetLanguageCode: 'zu',
    });
  });

  it('tries once more when Google is busy, and no more', async () => {
    const busy = (): { status: number; body: string } => ({ status: 503, body: '' });
    const { http, sent } = answering(busy, busy);
    const outcome = await new CloudTranslator(http, token('t'), 'p').translate(['x'], 'af');
    expect(outcome).toEqual({ kind: 'unavailable', reason: 'status 503' });
    expect(sent).toHaveLength(2);
  });

  it('does not retry a refusal', async () => {
    const { http, sent } = answering(() => ({ status: 403, body: '' }));
    await new CloudTranslator(http, token('t'), 'p').translate(['x'], 'af');
    expect(sent).toHaveLength(1);
  });

  it('reports a network failure as unavailable rather than throwing', async () => {
    const http: HttpClient = {
      send: () => Promise.reject(new HttpUnreachable('TimeoutError')),
    };
    const outcome = await new CloudTranslator(http, token('t'), 'p').translate(['x'], 'af');
    expect(outcome).toEqual({ kind: 'unavailable', reason: 'network: TimeoutError' });
  });

  it('asks nobody when there are no credentials', async () => {
    const { http, sent } = answering();
    const outcome = await new CloudTranslator(http, token(null), 'p').translate(['x'], 'af');
    expect(outcome).toEqual({ kind: 'unavailable', reason: 'no credentials' });
    expect(sent).toHaveLength(0);
  });
});

describe('the emulator’s translator', () => {
  it('marks each text with its language, so a test can see it happened', async () => {
    const outcome = await new EmulatorTranslator().translate(['Open a window'], 'ts');
    expect(outcome).toEqual({ kind: 'translated', texts: ['[ts] Open a window'] });
  });
});
