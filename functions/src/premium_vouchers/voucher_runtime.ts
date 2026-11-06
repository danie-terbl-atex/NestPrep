import { configured } from '../shared/configured_value';
import { runsInEmulator } from '../shared/feature_flags';
import { db } from '../shared/firestore';
import { consumeRateLimit } from '../shared/rate_limit';
import { callerEmailHashes, liveUserDirectory } from './caller_emails';
import { firestoreChallenges } from './email_challenges';
import { type EmailCodeDeps, randomEmailCode } from './email_code';
import { resendEmailSender, silentEmailSender } from '../shared/email_sender';
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
  const pepper = premiumPepper();
  const emulated = runsInEmulator();
  return {
    challenges: firestoreChallenges(store),
    provenHashes: (uid) => callerEmailHashes({ store, users: liveUserDirectory, pepper }, uid),
    pepper,
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

export function liveVerifyDeps(): Pick<EmailCodeDeps, 'challenges' | 'pepper' | 'now'> {
  return { challenges: firestoreChallenges(db()), pepper: premiumPepper(), now: new Date() };
}
