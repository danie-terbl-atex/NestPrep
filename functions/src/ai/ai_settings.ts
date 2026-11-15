import { z } from 'zod';

import type { ConversionTrigger } from '../product_analytics/conversion_ledger';

/**
 * The AI features, the switch that stops them all, and how many calls a
 * household gets a month (foundation ADR-0015).
 *
 * Every AI feature is named here once. `planMyWeek` is lunch-box's: both of
 * its steps, the ideas and the week, are counted and switched under it
 * (lunch-box ADR-0012). `lunchPhoto` is the picture of a box (lunch-box
 * ADR-0015). `productMatch` is the grocery list's ranking, switched here
 * but never counted (foundation ADR-0021). `listScan` reads a photo of a
 * shopping list (list-scan ADR-0001). `recipeImport` drafts a recipe from a
 * page, a photo or a PDF's pages (recipes ADR-0008, ADR-0009). `recipeDocument`
 * lists the recipes in a PDF (recipes ADR-0009). `avatarCheck` reads a
 * reference and checks a made picture, charged to nothing; `avatarCreate` and
 * `avatarPortrait` share the creations allowance (avatars ADR-0003, ADR-0006).
 */
export const AI_FEATURES = [
  'schoolLetter',
  'planMyWeek',
  'lunchPhoto',
  'productMatch',
  'listScan',
  'recipeImport',
  'recipeDocument',
  'avatarCheck',
  'avatarCreate',
  'avatarPortrait',
] as const;
export type AiFeature = (typeof AI_FEATURES)[number];

/** The Premium feature a free household is sent to the paywall for (subscriptions ADR-0008). */
export const PREMIUM_FEATURE_OF: Readonly<Record<AiFeature, ConversionTrigger>> = {
  schoolLetter: 'schoolLetter',
  planMyWeek: 'aiPlanning',
  lunchPhoto: 'lunchPhoto',
  productMatch: 'shops',
  listScan: 'listScan',
  recipeImport: 'ownRecipes',
  recipeDocument: 'ownRecipes',
  avatarCheck: 'avatarCreate',
  avatarCreate: 'avatarCreate',
  avatarPortrait: 'avatarPortrait',
};

/** The document an operator edits in the console to stop or loosen AI. */
export const AI_SETTINGS_COLLECTION = 'appConfig';
export const AI_SETTINGS_DOCUMENT = 'ai';

export interface MonthlyCalls {
  readonly free: number;
  readonly premium: number;
}

export interface Allowance {
  readonly premiumMonthly: number;
  readonly freeLifetime: number;
}

export const ALLOWANCES = ['avatarCreate'] as const;
export type AllowanceName = (typeof ALLOWANCES)[number];

export const ALLOWANCE_SHARES: Readonly<Record<AllowanceName, readonly AiFeature[]>> = {
  avatarCreate: ['avatarCreate', 'avatarPortrait'],
};

/** The checks made on the way to an allowance's creations: charged to nothing, counted with them. */
export const ALLOWANCE_CHECKS: Readonly<Record<AllowanceName, readonly AiFeature[]>> = {
  avatarCreate: ['avatarCheck'],
};

export interface AiSettings {
  /** The kill switch: false stops every AI call at once, before any cost. */
  readonly enabled: boolean;
  /** One switch per feature, under the kill switch. */
  readonly features: Readonly<Record<AiFeature, boolean>>;
  /** The calls one household may spend in one calendar month, per tier. */
  readonly monthlyCalls: MonthlyCalls;
  readonly allowances: Readonly<Record<AllowanceName, Allowance>>;
}

/**
 * What applies when nobody has written the document. The free tier has no AI
 * at all (subscriptions ADR-0008); a hundred a month on premium is more than
 * any family needs and still a bounded bill (foundation ADR-0015, verdict
 * 003's *AI cost per active family*).
 */
export const DEFAULT_AI_SETTINGS: AiSettings = {
  enabled: true,
  features: {
    schoolLetter: true,
    planMyWeek: true,
    lunchPhoto: true,
    productMatch: true,
    listScan: true,
    recipeImport: true,
    recipeDocument: true,
    avatarCheck: true,
    avatarCreate: true,
    avatarPortrait: true,
  },
  monthlyCalls: { free: 0, premium: 100 },
  allowances: { avatarCreate: { premiumMonthly: 12, freeLifetime: 0 } },
};

/** A cap nobody means; past it, a typo in the console is a bill. */
export const MAX_MONTHLY_CALLS = 1_000;

const cap = z.number().int().min(0).max(MAX_MONTHLY_CALLS);

/**
 * The stored document, read defensively. Absent is the defaults. **A present
 * `enabled` that is not a boolean reads as off** — somebody was reaching for
 * the kill switch, and a typo must not leave it open. A feature switch or cap
 * that does not parse keeps its default, because those only ever narrow.
 * **A stored free number is never read**: the free tier's zero is the map, not
 * a setting, so a document written before 2026-11-15 cannot hand it calls.
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
  const storedCalls = z.object({ premium: cap.optional() }).safeParse(data['monthlyCalls']);
  const monthlyCalls = {
    free: DEFAULT_AI_SETTINGS.monthlyCalls.free,
    premium:
      (storedCalls.success ? storedCalls.data.premium : undefined) ??
      DEFAULT_AI_SETTINGS.monthlyCalls.premium,
  };
  const allowances = Object.fromEntries(
    ALLOWANCES.map((name) => [
      name,
      readAllowance(storedFeatures.success ? storedFeatures.data[name] : undefined, name),
    ]),
  ) as Record<AllowanceName, Allowance>;
  return { enabled, features, monthlyCalls, allowances };
}

function readAllowance(stored: unknown, name: AllowanceName): Allowance {
  const fallback = DEFAULT_AI_SETTINGS.allowances[name];
  const parsed = z.object({ premiumMonthly: cap.optional() }).safeParse(stored);
  if (!parsed.success) return fallback;
  return {
    premiumMonthly: parsed.data.premiumMonthly ?? fallback.premiumMonthly,
    freeLifetime: fallback.freeLifetime,
  };
}

export function isFeatureOn(settings: AiSettings, feature: AiFeature): boolean {
  return settings.enabled && settings.features[feature];
}

export type AiCharge =
  | { readonly kind: 'calls' }
  | { readonly kind: 'none'; readonly name: AllowanceName; readonly allowance: Allowance }
  | {
      readonly kind: 'allowance';
      readonly name: AllowanceName;
      readonly shares: readonly AiFeature[];
      readonly allowance: Allowance;
    };

export function allowanceOf(feature: AiFeature): AllowanceName | undefined {
  return ALLOWANCES.find((name) => ALLOWANCE_SHARES[name].includes(feature));
}

export function chargeOf(settings: AiSettings, feature: AiFeature): AiCharge {
  const checked = ALLOWANCES.find((name) => ALLOWANCE_CHECKS[name].includes(feature));
  if (checked !== undefined) {
    return { kind: 'none', name: checked, allowance: settings.allowances[checked] };
  }
  const name = allowanceOf(feature);
  if (name === undefined) return { kind: 'calls' };
  return {
    kind: 'allowance',
    name,
    shares: ALLOWANCE_SHARES[name],
    allowance: settings.allowances[name],
  };
}
