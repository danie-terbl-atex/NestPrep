import { defineSecret, defineString } from 'firebase-functions/params';

/**
 * Which model answers, and where (foundation ADR-0015, BE-16). Parameters
 * rather than constants so a retired model or a new region is a config
 * change, not a code change; neither is a secret, and there is no key — the
 * call runs as the Functions' service account.
 *
 * - `AI_MODEL` — a Gemini model id on Vertex AI. `gemini-2.5-flash` answered
 *   in `europe-west4` on 2026-09-29 (the ADR's smoke call).
 * - `AI_LOCATION` — the Vertex region the family's request is processed in.
 *   `africa-south1` hosts no Gemini model; `europe-west4` (the Netherlands) is
 *   the ADR's choice, under the GDPR and so an adequate jurisdiction for
 *   POPIA section 72.
 */
export const aiModel = defineString('AI_MODEL', { default: 'gemini-2.5-flash' });
export const aiLocation = defineString('AI_LOCATION', { default: 'europe-west4' });

/**
 * The image model and its endpoint (lunch-box ADR-0016): a Gemini image model,
 * served only from Vertex's `global` endpoint. Its prompt names foods and
 * nothing about a family.
 */
export const aiImageModel = defineString('AI_IMAGE_MODEL', { default: 'gemini-3.1-flash-image' });
export const aiImageLocation = defineString('AI_IMAGE_LOCATION', { default: 'global' });

/** Jev on TypeSafe makes the decisions (foundation ADR-0021); the key is a secret. */
export const aiDecisionModel = defineString('AI_DECISION_MODEL', { default: 'jev-latest' });
export const typesafeApiKey = defineSecret('TYPESAFE_API_KEY');
export const DECISION_SECRETS = [typesafeApiKey];

/** The project the Functions run in, which is the one Vertex bills. */
export function currentProject(): string {
  const project = process.env['GCLOUD_PROJECT'] ?? process.env['GOOGLE_CLOUD_PROJECT'];
  if (project === undefined || project === '') {
    throw new Error('No project id in the environment; Vertex cannot be addressed.');
  }
  return project;
}
