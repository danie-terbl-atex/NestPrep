import type { HttpClient } from '../shared/http_client';
import type { PnpClient } from './pnp_api';
import { OCC_LOCALE, PNP_OCC, askPnp, readPnpReply } from './pnp_request';
import { configReply, pnpClientOf } from './pnp_wire';

/** How long an instance trusts the client it read before asking PnP again. */
export const CLIENT_CONFIG_TTL_MS = 60 * 60 * 1000;

interface Remembered {
  readonly client: PnpClient;
  readonly until: number;
}

// One per instance, so linking and every push do not each read `/config`.
let remembered: Remembered | null = null;

/**
 * The website's OIDC client, read where PnP publishes it — its `/config`,
 * served to every browser — rather than kept in the repo or Function config,
 * so a rotation on PnP's side is followed for free (add-to-pnp ADR-0003).
 * Never logged.
 */
export async function readPnpClient(http: HttpClient, now: Date): Promise<PnpClient> {
  if (remembered !== null && remembered.until > now.getTime()) return remembered.client;
  const reply = await askPnp(http, `${PNP_OCC}/config?${OCC_LOCALE}`, {
    method: 'GET',
    headers: { Accept: 'application/json' },
  });
  const client = pnpClientOf(readPnpReply(configReply, reply));
  remembered = { client, until: now.getTime() + CLIENT_CONFIG_TTL_MS };
  return client;
}

/** Forgets the client, after PnP said it no longer knows it. */
export function forgetPnpClient(): void {
  remembered = null;
}
