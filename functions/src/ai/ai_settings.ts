import { z } from 'zod';

/**
 * The AI features, the switch that stops them all, and how many calls a
 * household gets a month (foundation ADR-0015).
 *
 * Every AI feature is named here once. `planMyWeek` is lunch-box's: both of
 * its steps, the ideas and the week, are counted and switched under it
 * (lunch-box ADR-0012).
 */
export const AI_FEATURES = ['schoolLetter', 'planMyWeek'] as const;
export type AiFeature = (typeof AI_FEATURES)[number];

/** The document an operator edits in the console to stop or loosen AI. */
export const AI_SETTINGS_COLLECTION = 'appConfig';
export const AI_SETTINGS_DOCUMENT = 'ai';

export interface MonthlyCalls {
  readonly free: number;
  readonly premium: number;
}

export interface AiSettings {
  /** The kill switch: false stops every AI call at once, before any cost. */
  readonly enabled: boolean;
  /** One switch per feature, under the kill switch. */
  readonly features: Readonly<Record<AiFeature, boolean>>;
  /** The calls one household may spend in one calendar month, per tier. */
  readonly monthlyCalls: MonthlyCalls;
}

/**
 * What applies when nobody has written the document. Ten a month on the free
 * tier is two school letters a week and a weekly plan; a hundred on premium
 * is more than any family needs and still a bounded bill (foundation ADR-0015,
 * verdict 003's *AI cost per active family*).
 */
export const DEFAULT_AI_SETTINGS: AiSettings = {
  enabled: true,
  features: { schoolLetter: true, planMyWeek: true },
  monthlyCalls: { free: 10, premium: 100 },
};

/** A cap nobody means; past it, a typo in the console is a bill. */
export const MAX_MONTHLY_CALLS = 1_000;

const cap = z.number().int().min(0).max(MAX_MONTHLY_CALLS);

/**
 * The stored document, read defensively. Absent is the defaults. **A present
 * `enabled` that is not a boolean reads as off** — somebody was reaching for
 * the kill switch, and a typo must not leave it open. A feature switch or cap
 * that does not parse keeps its default, because those only ever narrow.
 */
export function readAiSettings(stored: unknown): AiSettings {
  if (stored === undefined || stored === null) return DEFAULT_AI_SETTINGS;
  const document = z.record(z.string(), z.unknown()).safeParse(stored);
  if (!document.success) return { ...DEFAULT_AI_SETTINGS, enabled: false };
  const data = document.data;

  const enabled = data['enabled'] === undefined ? true : data['enabled'] === true;
  const storedFeatures = z.record(z.string(), z.unknown()).safeParse(data['features']);
  const features = { ...DEFAULT_AI_SETTINGS.features };
  if (storedFeatures.success) {
    for (const feature of AI_FEATURES) {
      if (storedFeatures.data[feature] === false) features[feature] = false;
    }
  }
  const storedCalls = z
    .object({ free: cap.optional(), premium: cap.optional() })
    .safeParse(data['monthlyCalls']);
  const monthlyCalls = {
    free:
      (storedCalls.success ? storedCalls.data.free : undefined) ??
      DEFAULT_AI_SETTINGS.monthlyCalls.free,
    premium:
      (storedCalls.success ? storedCalls.data.premium : undefined) ??
      DEFAULT_AI_SETTINGS.monthlyCalls.premium,
  };
  return { enabled, features, monthlyCalls };
}

export function isFeatureOn(settings: AiSettings, feature: AiFeature): boolean {
  return settings.enabled && settings.features[feature];
}
