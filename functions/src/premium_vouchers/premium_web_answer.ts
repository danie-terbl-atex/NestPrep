import type { Firestore } from 'firebase-admin/firestore';
import type { z } from 'zod';

import type { RateLimitRule } from '../shared/rate_limit';
import {
  codeHashOf,
  emailHashOf,
  maskEmail,
  normCode,
  normEmail,
  tokenHashOf,
} from './premium_hashes';
import {
  GIFT_LOOKUP_OVERALL,
  GIFT_LOOKUP_PER_ADDRESS,
  PREMIUM_WEB_OVERALL,
  PREMIUM_WEB_PER_ADDRESS,
  PREMIUM_WEB_PER_EMAIL,
} from './premium_web_limits';
import { giftLookupInput, giftReassignInput, redeemCodeInput } from './schemas';
import {
  GIFT_LOOKUP_REFUSALS,
  GIFT_REASSIGN_REFUSALS,
  GIFT_TOKEN,
  lookUpGift,
  reassignGift,
} from './web_gifts';
import { REDEEM_REFUSALS, redeemCode } from './web_redemption';

export const WEB_ERROR_STATUS = {
  badRequest: 400,
  badEmail: 400,
  badCode: 400,
  voucherNotFound: 404,
  codeUnknown: 404,
  notFound: 404,
  methodNotAllowed: 405,
  voucherClaimed: 409,
  voucherVoid: 409,
  voucherReassignLimit: 409,
  codeNotStarted: 409,
  codeExpired: 409,
  codePaused: 409,
  codeUsedUp: 409,
  tooManyTries: 429,
  unavailable: 503,
} as const;
export type WebError = keyof typeof WEB_ERROR_STATUS;

export const WEB_ROUTES = ['/gift/lookup', '/gift/reassign', '/redeem'] as const;
export type WebRoute = (typeof WEB_ROUTES)[number];

export const WEB_ROUTE_REFUSALS = {
  '/gift/lookup': ['badRequest', ...GIFT_LOOKUP_REFUSALS, 'tooManyTries'],
  '/gift/reassign': ['badRequest', 'badEmail', ...GIFT_REASSIGN_REFUSALS, 'tooManyTries'],
  '/redeem': ['badRequest', 'badCode', 'badEmail', ...REDEEM_REFUSALS, 'tooManyTries'],
} as const satisfies Record<WebRoute, readonly WebError[]>;

export interface WebRequest {
  readonly method: string;
  readonly path: string;
  readonly body: unknown;
}

export interface WebReply {
  readonly status: number;
  readonly body: Readonly<Record<string, unknown>>;
}

export interface PremiumWebDeps {
  readonly store: Firestore;
  readonly pepper: () => string;
  readonly address: string;
  readonly now: Date;
  readonly consume: (rule: RateLimitRule, subject: string) => Promise<boolean>;
  readonly isWithin: (rule: RateLimitRule, subject: string) => Promise<boolean>;
}

type Answer = Readonly<Record<string, unknown>> & { readonly error?: WebError };

const TOO_MANY: Answer = { error: 'tooManyTries' };

export function routeOf(path: string): WebRoute | null {
  const route = path.replace(/^\/api\/premium(?=\/)/, '').replace(/\/+$/, '');
  return (WEB_ROUTES as readonly string[]).includes(route) ? (route as WebRoute) : null;
}

export async function answerPremiumWeb(
  deps: PremiumWebDeps,
  request: WebRequest,
): Promise<WebReply> {
  if (request.method !== 'POST') return replyOf({ error: 'methodNotAllowed' });
  const route = routeOf(request.path);
  if (route === null) return replyOf({ error: 'notFound' });
  const perAddress = route === '/gift/lookup' ? GIFT_LOOKUP_PER_ADDRESS : PREMIUM_WEB_PER_ADDRESS;
  if (!(await deps.consume(perAddress, deps.address))) return replyOf(TOO_MANY);
  return replyOf(await answerRoute(deps, route, request.body));
}

async function answerRoute(deps: PremiumWebDeps, route: WebRoute, body: unknown): Promise<Answer> {
  switch (route) {
    case '/gift/lookup': {
      const input = parsed(giftLookupInput, body);
      if (input === null) return { error: 'badRequest' };
      if (!GIFT_TOKEN.test(input.token)) return { error: 'voucherNotFound' };
      if (!(await deps.consume(GIFT_LOOKUP_OVERALL, 'all'))) return TOO_MANY;
      return lookUpGift(deps.store, tokenHashOf(input.token));
    }
    case '/gift/reassign': {
      const input = parsed(giftReassignInput, body);
      if (input === null) return { error: 'badRequest' };
      if (!GIFT_TOKEN.test(input.token)) return { error: 'voucherNotFound' };
      const email = normEmail(input.email);
      if (email === null) return { error: 'badEmail' };
      const emailHash = await emailHashOf(deps.pepper(), email);
      if (!(await deps.consume(PREMIUM_WEB_PER_EMAIL, emailHash))) return TOO_MANY;
      if (!(await deps.consume(PREMIUM_WEB_OVERALL, 'all'))) return TOO_MANY;
      return reassignGift(
        deps.store,
        { claimTokenHash: tokenHashOf(input.token), emailHash, emailMasked: maskEmail(email) },
        deps.now,
      );
    }
    case '/redeem': {
      const input = parsed(redeemCodeInput, body);
      if (input === null) return { error: 'badRequest' };
      const code = normCode(input.code);
      if (code === null) return { error: 'badCode' };
      const email = normEmail(input.email);
      if (email === null) return { error: 'badEmail' };
      const pepper = deps.pepper();
      const emailHash = await emailHashOf(pepper, email);
      if (!(await deps.isWithin(PREMIUM_WEB_PER_EMAIL, emailHash))) return TOO_MANY;
      if (!(await deps.consume(PREMIUM_WEB_OVERALL, 'all'))) return TOO_MANY;
      const answer = await redeemCode(
        deps.store,
        { codeHash: await codeHashOf(pepper, code), emailHash, emailMasked: maskEmail(email) },
        deps.now,
      );
      if ('error' in answer) await deps.consume(PREMIUM_WEB_PER_EMAIL, emailHash);
      return answer;
    }
  }
}

function parsed<S extends z.ZodType>(schema: S, body: unknown): z.infer<S> | null {
  const result = schema.safeParse(body);
  return result.success ? result.data : null;
}

function replyOf(answer: Answer): WebReply {
  return {
    status: answer.error === undefined ? 200 : WEB_ERROR_STATUS[answer.error],
    body: answer,
  };
}
