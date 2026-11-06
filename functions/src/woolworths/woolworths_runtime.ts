import type { Firestore } from 'firebase-admin/firestore';
import { logger } from 'firebase-functions/v2';

import { configured } from '../shared/configured_value';
import { readFlag, runsInEmulator } from '../shared/feature_flags';
import { fetchHttpClient } from '../shared/http_client';
import { sessionKeyFrom } from '../shared/session_crypto';
import { EmulatorWoolworths } from './emulator_woolworths';
import { HttpWoolworthsLogin } from './http_woolworths_login';
import { HttpWoolworthsShop } from './http_woolworths_shop';
import type { WoolworthsLogin, WoolworthsShop } from './woolworths_api';
import {
  woolworthsAppIdentity,
  woolworthsCognito,
  woolworthsSessionKey,
  type WoolworthsCognito,
} from './woolworths_config';
import { refuseWoolworths } from './woolworths_errors';

const EMULATOR_SESSION_KEY = Buffer.alloc(32, 11);

export const EMULATOR_COGNITO: WoolworthsCognito = {
  clientId: 'emulatorWoolworthsClient',
  region: 'xx-emulator-1',
};

export async function requireAddToWoolworths(store: Firestore): Promise<void> {
  if (!(await readFlag(store, 'addToWoolworths'))) {
    throw refuseWoolworths('woolworths-switched-off');
  }
}

export function woolworthsCognitoHere(): WoolworthsCognito {
  const cognito = woolworthsCognito();
  if (cognito !== null) return cognito;
  if (runsInEmulator()) return EMULATOR_COGNITO;
  logger.error('WOOLWORTHS_COGNITO_CLIENT_ID or WOOLWORTHS_COGNITO_REGION is not configured');
  throw refuseWoolworths('woolworths-unavailable');
}

export function woolworthsLoginHere(): WoolworthsLogin {
  if (runsInEmulator()) return new EmulatorWoolworths();
  return new HttpWoolworthsLogin(fetchHttpClient, woolworthsCognitoHere());
}

export function woolworthsHere(): { login: WoolworthsLogin; shop: WoolworthsShop } {
  if (runsInEmulator()) {
    const emulator = new EmulatorWoolworths();
    return { login: emulator, shop: emulator };
  }
  const login = woolworthsLoginHere();
  const app = woolworthsAppIdentity();
  if (app === null) {
    logger.error('woolworths app identity is not configured');
    throw refuseWoolworths('woolworths-unavailable');
  }
  return { login, shop: new HttpWoolworthsShop(fetchHttpClient, app) };
}

export function woolworthsSessionKeyHere(): Buffer {
  const key = sessionKeyFrom(configured(woolworthsSessionKey.value()));
  if (key !== null) return key;
  if (runsInEmulator()) return EMULATOR_SESSION_KEY;
  logger.error('WOOLWORTHS_SESSION_KEY is missing or is not 32 bytes of base64');
  throw refuseWoolworths('woolworths-unavailable');
}
