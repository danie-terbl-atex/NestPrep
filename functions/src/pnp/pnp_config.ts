import { defineSecret } from 'firebase-functions/params';

/**
 * Add to Pick n Pay's configuration, by name (BE-16, ENG-18; add-to-pnp
 * ADR-0003). There is only the key: PnP's OIDC client id and secret are read
 * from PnP's own `/config` at runtime, never kept here.
 *
 * - `PNP_SESSION_KEY` (secret) — 32 random bytes, base64: the AES-256-GCM key
 *   every stored PnP token and pending link is sealed with.
 */
export const pnpSessionKey = defineSecret('PNP_SESSION_KEY');

/** What the callables that seal or open a PnP link are bound to. */
export const PNP_SECRETS = [pnpSessionKey];
