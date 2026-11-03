import { defineSecret, defineString } from 'firebase-functions/params';
import { logger } from 'firebase-functions/v2';

import { configured } from '../shared/configured_value';
import { runsInEmulator } from '../shared/feature_flags';

export const premiumEmailPepper = defineSecret('PREMIUM_EMAIL_PEPPER');
export const resendApiKey = defineSecret('RESEND_API_KEY');
export const premiumEmailFrom = defineString('PREMIUM_EMAIL_FROM', { default: '' });
export const storeInvokerServiceAccount = defineString('STORE_INVOKER_SERVICE_ACCOUNT', {
  default: '',
});
export const premiumTesterUids = defineString('PREMIUM_TESTER_UIDS', { default: '' });

export const EMULATOR_PEPPER = 'nestprep-emulator-premium-pepper';

export function premiumPepper(): string {
  const pepper = configured(premiumEmailPepper.value());
  if (pepper !== null) return pepper;
  if (runsInEmulator()) return EMULATOR_PEPPER;
  logger.error('PREMIUM_EMAIL_PEPPER is not configured');
  throw new Error('PREMIUM_EMAIL_PEPPER is not configured');
}

export function premiumTesters(): readonly string[] {
  return testerUidsFrom(premiumTesterUids.value());
}

export function testerUidsFrom(value: string): string[] {
  return value
    .split(',')
    .map((uid) => uid.trim())
    .filter((uid) => uid !== '' && uid !== 'unset');
}

export function storeInvokerEmail(): string | null {
  const email = configured(storeInvokerServiceAccount.value());
  return email === null ? null : email.toLowerCase();
}
