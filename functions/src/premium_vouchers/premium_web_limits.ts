import type { RateLimitRule } from '../shared/rate_limit';

const FIFTEEN_MINUTES = 15 * 60;
const HOUR = 60 * 60;

export const GIFT_LOOKUP_PER_ADDRESS: RateLimitRule = {
  name: 'premiumWeb:lookup:address',
  limit: 60,
  windowSeconds: FIFTEEN_MINUTES,
};

export const GIFT_REASSIGN_PER_ADDRESS: RateLimitRule = {
  name: 'premiumWeb:address',
  limit: 30,
  windowSeconds: FIFTEEN_MINUTES,
};

export const PREMIUM_WEB_PER_EMAIL: RateLimitRule = {
  name: 'premiumWeb:email',
  limit: 10,
  windowSeconds: HOUR,
};

export const REDEEM_PER_ADDRESS: RateLimitRule = {
  name: 'premiumWeb:redeem:address',
  limit: 30,
  windowSeconds: FIFTEEN_MINUTES,
};

export const REDEEM_MISSES_PER_ADDRESS: RateLimitRule = {
  name: 'premiumWeb:redeem:misses:address',
  limit: 10,
  windowSeconds: FIFTEEN_MINUTES,
};

export const REDEEMED_PER_ADDRESS: RateLimitRule = {
  name: 'premiumWeb:redeem:redeemed:address',
  limit: 10,
  windowSeconds: HOUR,
};

export const REDEEM_MISSES_OVERALL: RateLimitRule = {
  name: 'premiumWeb:redeem:misses:all',
  limit: 2_000,
  windowSeconds: HOUR,
};

export const REDEEM_MISSES_TRIPPED: RateLimitRule = {
  name: 'premiumWeb:redeem:misses:tripped',
  limit: 1,
  windowSeconds: HOUR,
};
