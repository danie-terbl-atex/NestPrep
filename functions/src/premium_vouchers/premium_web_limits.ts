import type { RateLimitRule } from '../shared/rate_limit';

const FIFTEEN_MINUTES = 15 * 60;
const HOUR = 60 * 60;

export const GIFT_LOOKUP_PER_ADDRESS: RateLimitRule = {
  name: 'premiumWeb:lookup:address',
  limit: 60,
  windowSeconds: FIFTEEN_MINUTES,
};

export const GIFT_LOOKUP_OVERALL: RateLimitRule = {
  name: 'premiumWeb:lookup:all',
  limit: 10_000,
  windowSeconds: HOUR,
};

export const PREMIUM_WEB_PER_ADDRESS: RateLimitRule = {
  name: 'premiumWeb:address',
  limit: 30,
  windowSeconds: FIFTEEN_MINUTES,
};

export const PREMIUM_WEB_OVERALL: RateLimitRule = {
  name: 'premiumWeb:all',
  limit: 3_000,
  windowSeconds: HOUR,
};

export const PREMIUM_WEB_PER_EMAIL: RateLimitRule = {
  name: 'premiumWeb:email',
  limit: 10,
  windowSeconds: HOUR,
};
