import { GoogleAuth } from 'google-auth-library';
import { z } from 'zod';

import { HttpUnreachable, jsonOf, type HttpClient } from '../shared/http_client';
import { SOURCE_LANGUAGE, type TargetLanguage } from './languages';
import type { TranslationOutcome, Translator } from './translator';

export const CLOUD_TRANSLATION_SCOPE = 'https://www.googleapis.com/auth/cloud-translation';

/** Where the bearer token comes from — behind an interface so tests hand in a canned one. */
export interface TranslationToken {
  token(): Promise<string | null>;
}

/**
 * The Functions runtime's own service account, through application-default
 * credentials — no key anywhere (home-care ADR-0006, ENG-18). It needs
 * `roles/cloudtranslate.user` and the Cloud Translation API enabled; until
 * then Google answers 403 and the helper reads English.
 */
export class ApplicationDefaultTranslationToken implements TranslationToken {
  private readonly auth = new GoogleAuth({ scopes: [CLOUD_TRANSLATION_SCOPE] });

  async token(): Promise<string | null> {
    try {
      const token = await this.auth.getAccessToken();
      return typeof token === 'string' && token !== '' ? token : null;
    } catch (error) {
      // No credentials on this machine, or the metadata server would not
      // answer: Google cannot be asked, which the caller reports as such.
      if (error instanceof Error) return null;
      throw error;
    }
  }
}

const translateReply = z.object({
  translations: z.array(z.object({ translatedText: z.string() })),
});

/**
 * Google Cloud Translation v3 (NMT) through the one HTTP client with its
 * timeout (BE-09, BE-19). One request per batch; one retry when Google is
 * busy or failing, because translating the same texts twice is harmless.
 */
export class CloudTranslator implements Translator {
  readonly engine = 'cloudTranslation';

  constructor(
    private readonly http: HttpClient,
    private readonly credentials: TranslationToken,
    private readonly project: string,
  ) {}

  async translate(texts: readonly string[], target: TargetLanguage): Promise<TranslationOutcome> {
    const token = await this.credentials.token();
    if (token === null) return { kind: 'unavailable', reason: 'no credentials' };
    const first = await this.ask(texts, target, token);
    return isWorthRetrying(first) ? this.ask(texts, target, token) : first;
  }

  private async ask(
    texts: readonly string[],
    target: TargetLanguage,
    token: string,
  ): Promise<TranslationOutcome> {
    const url =
      `https://translation.googleapis.com/v3/projects/${this.project}` +
      '/locations/global:translateText';
    try {
      const response = await this.http.send(url, {
        method: 'POST',
        headers: { Authorization: `Bearer ${token}`, 'Content-Type': 'application/json' },
        body: JSON.stringify({
          contents: texts,
          mimeType: 'text/plain',
          sourceLanguageCode: SOURCE_LANGUAGE,
          targetLanguageCode: target,
        }),
      });
      return outcomeOf(response.status, response.body, texts.length);
    } catch (error) {
      if (error instanceof HttpUnreachable) {
        return { kind: 'unavailable', reason: `network: ${error.reason}` };
      }
      throw error;
    }
  }
}

/** Google's answer, read as one of the three outcomes; never cast (ENG-09). */
export function outcomeOf(status: number, body: string, asked: number): TranslationOutcome {
  if (status === 400) return { kind: 'unsupported' };
  if (status === 401 || status === 403) return { kind: 'unavailable', reason: 'refused' };
  if (status !== 200) return { kind: 'unavailable', reason: `status ${String(status)}` };
  const reply = translateReply.safeParse(jsonOf(body));
  if (!reply.success || reply.data.translations.length !== asked) {
    return { kind: 'unavailable', reason: 'unreadable' };
  }
  return { kind: 'translated', texts: reply.data.translations.map((line) => line.translatedText) };
}

/** Busy, failing or unreachable is worth one more try; a refusal or nonsense is not. */
export function isWorthRetrying(outcome: TranslationOutcome): boolean {
  if (outcome.kind !== 'unavailable') return false;
  const { reason } = outcome;
  return reason === 'status 429' || reason.startsWith('status 5') || reason.startsWith('network:');
}
