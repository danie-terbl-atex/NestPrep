import type { Firestore } from 'firebase-admin/firestore';
import { logger } from 'firebase-functions/v2';

import { configured } from '../shared/configured_value';
import { readFlag, runsInEmulator } from '../shared/feature_flags';
import { fetchHttpClient } from '../shared/http_client';
import type { CheckersLogin, CheckersShop } from './checkers_api';
import { checkersAppIdentity, checkersSessionKey } from './checkers_config';
import { EmulatorCheckers } from './emulator_checkers';
import { refuseCheckers } from './errors';
import { HttpCheckersLogin } from './http_checkers_login';
import { HttpCheckersShop } from './http_checkers_shop';
import { sessionKeyFrom } from './session_crypto';

/**
 * The emulator's session key when none is configured locally — for sealing
 * the emulator's scripted sessions, which reach nothing (BE-16: a committed
 * default points only at a local sandbox). The cloud never reads it.
 */
const EMULATOR_SESSION_KEY = Buffer.alloc(32, 7);

/** Refuses with `checkers-switched-off` unless `appConfig/flags.addToCheckers` is on. */
export async function requireAddToCheckers(store: Firestore): Promise<void> {
  if (!(await readFlag(store, 'addToCheckers'))) throw refuseCheckers('checkers-switched-off');
}

/** Checkers in the cloud; the script under the emulator, so nothing local sends an SMS. */
export function checkersHere(): { login: CheckersLogin; shop: CheckersShop } {
  if (runsInEmulator()) {
    const emulator = new EmulatorCheckers();
    return { login: emulator, shop: emulator };
  }
  const app = checkersAppIdentity();
  if (app === null) {
    // A deploy without the app identity is a configuration fault: loud in
    // the log, and "Checkers is not answering" to the member (BE-16).
    logger.error('checkers app identity is not configured');
    throw refuseCheckers('checkers-down');
  }
  return {
    login: new HttpCheckersLogin(fetchHttpClient, app),
    shop: new HttpCheckersShop(fetchHttpClient, app),
  };
}

/** The key every link is sealed with; a missing or malformed one refuses loudly. */
export function sessionKeyHere(): Buffer {
  const key = sessionKeyFrom(configured(checkersSessionKey.value()));
  if (key !== null) return key;
  if (runsInEmulator()) return EMULATOR_SESSION_KEY;
  logger.error('CHECKERS_SESSION_KEY is missing or is not 32 bytes of base64');
  throw refuseCheckers('checkers-down');
}
