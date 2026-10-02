import { randomBytes } from 'node:crypto';

import { logger } from 'firebase-functions/v2';

import {
  CheckersRefused,
  CheckersUnavailable,
  type CheckersLogin,
  type LinkedAccount,
  type PendingOtp,
} from './checkers_api';
import { refuseCheckers } from './errors';
import type { CheckersLinkStore } from './link_store';
import { linkStatusOf, type LinkStatus } from './link_status';
import { maskMobile, normaliseSaMobile } from './mobile_number';
import { openPending, sealPending, sealSession } from './sealed_values';

/** How long a sent code can be verified — Checkers' own codes lapse sooner. */
export const PENDING_OTP_MINUTES = 10;

/** Wrong codes tried against one sent code before it is thrown away. */
export const MAX_CODE_ATTEMPTS = 5;

/** The session is treated as lapsed this long before Checkers says it is. */
export const SESSION_SKEW_SECONDS = 60;

export interface OtpLinkDeps {
  readonly links: CheckersLinkStore;
  readonly login: CheckersLogin;
  readonly key: Buffer;
  readonly now: Date;
}

export interface CodeRequestDeps extends OtpLinkDeps {
  /** Counts one code asked for, by this account and to this number; false is over the limit. */
  readonly allowCode: (uid: string, mobile: string) => Promise<boolean>;
}

/**
 * Sends a Checkers login code to the member's own number and keeps what
 * verifying it needs, sealed (the Checkers build contract). Only ever on the
 * member's explicit ask; rate-limited per account and per number, so it
 * cannot be used to flood somebody with SMS.
 */
export async function requestLinkOtp(
  deps: CodeRequestDeps,
  uid: string,
  typedMobile: string,
): Promise<{ sent: true; mobileMasked: string }> {
  const mobile = normaliseSaMobile(typedMobile);
  if (mobile === null) throw refuseCheckers('bad-mobile');
  if (!(await deps.allowCode(uid, mobile))) throw refuseCheckers('otp-rate-limited');

  const existing = await deps.links.read(uid);
  const deviceId = existing?.deviceId ?? randomBytes(8).toString('hex');
  const pending = await sendCode(deps.login, mobile, deviceId);
  const mobileMasked = maskMobile(mobile);
  await deps.links.savePending(uid, deviceId, {
    sealed: await sealPending(deps.key, uid, pending),
    expiresAt: new Date(deps.now.getTime() + PENDING_OTP_MINUTES * 60_000),
    attempts: 0,
    mobileMasked,
  });
  logger.info('checkers code sent', { uid, route: pending.route });
  return { sent: true, mobileMasked };
}

/**
 * Verifies the code against the one sent, and stores the hour-long session
 * that gives, sealed. The attempt is counted before Checkers is asked, so a
 * guess cannot be retried faster than the limit.
 */
export async function verifyLinkOtp(
  deps: OtpLinkDeps,
  uid: string,
  code: string,
): Promise<LinkStatus & { linked: true }> {
  const claimed = await deps.links.claimAttempt(uid, deps.now, MAX_CODE_ATTEMPTS);
  if (claimed === null) throw refuseCheckers('no-pending-otp');
  const pending = await openPending(deps.key, uid, claimed.pending.sealed);
  if (pending === null) {
    logger.warn('checkers pending code does not open', { uid });
    throw refuseCheckers('no-pending-otp');
  }

  const account = await verifyCode(deps.login, pending, code, claimed.deviceId);
  const lifetimeMs = (account.expiresInSeconds - SESSION_SKEW_SECONDS) * 1000;
  const session = {
    sealed: await sealSession(deps.key, uid, account.session),
    expiresAt: new Date(deps.now.getTime() + lifetimeMs),
    storeContexts: account.storeContexts,
    mobileMasked: claimed.pending.mobileMasked,
  };
  await deps.links.saveSession(uid, claimed.deviceId, session);
  logger.info('checkers account linked', { uid, stores: account.storeContexts.length });
  const status = linkStatusOf({ deviceId: claimed.deviceId, pending: null, session }, deps.now);
  return { ...status, linked: true };
}

async function sendCode(
  login: CheckersLogin,
  mobile: string,
  deviceId: string,
): Promise<PendingOtp> {
  try {
    return await login.requestOtp(mobile, deviceId);
  } catch (error) {
    if (error instanceof CheckersRefused) throw refuseCheckers('bad-mobile');
    if (error instanceof CheckersUnavailable) {
      logger.warn('checkers code not sent', { reason: error.reason });
      throw refuseCheckers('checkers-down');
    }
    throw error;
  }
}

async function verifyCode(
  login: CheckersLogin,
  pending: PendingOtp,
  code: string,
  deviceId: string,
): Promise<LinkedAccount> {
  try {
    return await login.verifyOtp(pending, code, deviceId);
  } catch (error) {
    if (error instanceof CheckersRefused) throw refuseCheckers('wrong-code');
    if (error instanceof CheckersUnavailable) {
      logger.warn('checkers code not verified', { reason: error.reason });
      throw refuseCheckers('checkers-down');
    }
    throw error;
  }
}
