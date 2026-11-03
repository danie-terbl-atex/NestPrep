import { configured } from '../shared/configured_value';
import { runsInEmulator } from '../shared/feature_flags';
import { db } from '../shared/firestore';
import { consumeRateLimit } from '../shared/rate_limit';
import { liveUserDirectory } from './caller_emails';
import { type EmailCodeDeps, randomEmailCode } from './email_code';
import { resendEmailSender, silentEmailSender } from './email_sender';
import { premiumEmailFrom, premiumPepper, premiumTesters, resendApiKey } from './premium_config';
import type { VoucherDeps } from './voucher_deps';

export const EMULATOR_EMAIL_CODE = '123456';

export function liveVoucherDeps(): VoucherDeps {
  return {
    store: db(),
    users: liveUserDirectory,
    pepper: premiumPepper(),
    testers: premiumTesters(),
    now: new Date(),
  };
}

export function liveEmailCodeDeps(): EmailCodeDeps {
  const store = db();
  const now = new Date();
  const emulated = runsInEmulator();
  return {
    store,
    users: liveUserDirectory,
    pepper: premiumPepper(),
    sender: emulated
      ? silentEmailSender
      : resendEmailSender({
          apiKey: configured(resendApiKey.value()),
          from: configured(premiumEmailFrom.value()),
        }),
    newCode: emulated ? (): string => EMULATOR_EMAIL_CODE : randomEmailCode,
    consume: (rule, subject) => consumeRateLimit(store, rule, subject, now),
    now,
  };
}
