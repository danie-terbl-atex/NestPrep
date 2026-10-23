import type { Firestore } from 'firebase-admin/firestore';
import { logger } from 'firebase-functions/v2';

import { configured } from '../shared/configured_value';
import { readFlag, runsInEmulator } from '../shared/feature_flags';
import { fetchHttpClient } from '../shared/http_client';
import { sessionKeyFrom } from '../shared/session_crypto';
import { EmulatorPnp } from './emulator_pnp';
import { HttpPnpLogin } from './http_pnp_login';
import { HttpPnpShop } from './http_pnp_shop';
import type { PnpLogin, PnpShop } from './pnp_api';
import { pnpSessionKey } from './pnp_config';
import { refusePnp } from './pnp_errors';

/**
 * The emulator's sealing key when none is configured locally — for the
 * emulator's scripted tokens, which reach nothing (BE-16: a committed default
 * points only at a local sandbox). The cloud never reads it.
 */
const EMULATOR_SESSION_KEY = Buffer.alloc(32, 9);

/** Refuses with `pnp-switched-off` unless `appConfig/flags.addToPnp` is on. */
export async function requireAddToPnp(store: Firestore): Promise<void> {
  if (!(await readFlag(store, 'addToPnp'))) throw refusePnp('pnp-switched-off');
}

/** Pick n Pay in the cloud; the script under the emulator, so nothing local reaches PnP. */
export function pnpHere(): { login: PnpLogin; shop: PnpShop } {
  if (runsInEmulator()) {
    const emulator = new EmulatorPnp();
    return { login: emulator, shop: emulator };
  }
  return { login: new HttpPnpLogin(fetchHttpClient), shop: new HttpPnpShop(fetchHttpClient) };
}

/** The key every PnP link is sealed with; a missing or malformed one refuses loudly. */
export function pnpSessionKeyHere(): Buffer {
  const key = sessionKeyFrom(configured(pnpSessionKey.value()));
  if (key !== null) return key;
  if (runsInEmulator()) return EMULATOR_SESSION_KEY;
  logger.error('PNP_SESSION_KEY is missing or is not 32 bytes of base64');
  throw refusePnp('pnp-down');
}
