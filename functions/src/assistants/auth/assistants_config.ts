import type { Firestore } from 'firebase-admin/firestore';
import { defineSecret, defineString } from 'firebase-functions/params';
import { logger } from 'firebase-functions/v2';

import { configured } from '../../shared/configured_value';
import { runsInEmulator } from '../../shared/feature_flags';
import { sessionKeyFrom } from '../../shared/session_crypto';

const DEFAULT_ASSISTANTS_ORIGIN = 'https://nestprep-643b7.web.app';

/**
 * Where members reach NestPrep from an assistant (assistants ADR-0002): the
 * Hosting origin that fronts `assistantAuth` and `assistantMcp`. It is the
 * issuer, and `${origin}/mcp` is the one resource every token is for, so
 * moving to `mcp.nestprep.io` is this value and nothing else — though every
 * connection made before the move has to be made again.
 */
export const assistantsOrigin = defineString('ASSISTANTS_ORIGIN', {
  default: DEFAULT_ASSISTANTS_ORIGIN,
});

/**
 * `true` lets a client register a loopback redirect (`http://localhost:*` or
 * `http://127.0.0.1:*`, path `/callback`), which is how Claude Code and the
 * MCP Inspector sign in. Off by default: a loopback redirect is a client
 * nobody can vouch for (assistants ADR-0002).
 */
export const assistantsAllowLoopback = defineString('ASSISTANTS_ALLOW_LOOPBACK', {
  default: 'false',
});

/**
 * `ASSISTANTS_TOKEN_KEY` (secret) — 32 random bytes, base64: the AES-256-GCM
 * key that seals the token pair a refresh issued, kept on the spent refresh
 * token for a minute so a client's retry gets that same pair (assistants
 * ADR-0002). Rotating it costs only the retries in flight.
 */
export const assistantsTokenKey = defineSecret('ASSISTANTS_TOKEN_KEY');

/**
 * The emulator's sealing key when none is configured locally — for tokens
 * that reach nothing outside the emulator (BE-16). The cloud never reads it.
 */
const EMULATOR_TOKEN_KEY = Buffer.alloc(32, 7);

/** The key a refresh seals its pair with; a missing or malformed one refuses loudly. */
export function assistantsTokenKeyHere(): Buffer {
  const key = sessionKeyFrom(configured(assistantsTokenKey.value()));
  if (key !== null) return key;
  if (runsInEmulator()) return EMULATOR_TOKEN_KEY;
  logger.error('ASSISTANTS_TOKEN_KEY is missing or is not 32 bytes of base64');
  throw new Error('ASSISTANTS_TOKEN_KEY is not configured');
}

export interface AuthorizationServer {
  readonly issuer: string;
  readonly resource: string;
  readonly allowLoopbackRedirects: boolean;
}

/** The one protected resource every token is minted for (RFC 8707). */
export function resourceOf(origin: string): string {
  return `${origin}/mcp`;
}

/** Where a client learns how to sign in to that resource (RFC 9728), named in every 401. */
export function resourceMetadataOf(origin: string): string {
  return `${origin}/.well-known/oauth-protected-resource/mcp`;
}

/** The origin in force, with no trailing slash; empty or `unset` reads as the default. */
export function assistantsIssuer(): string {
  return (configured(assistantsOrigin.value()) ?? DEFAULT_ASSISTANTS_ORIGIN).replace(/\/+$/, '');
}

export function authorizationServer(): AuthorizationServer {
  const issuer = assistantsIssuer();
  return {
    issuer,
    resource: resourceOf(issuer),
    allowLoopbackRedirects: assistantsAllowLoopback.value() === 'true',
  };
}

/**
 * Under the emulator only, `assistantsEmulator/cimd.allowLoopback: true` lets
 * a client id be a plain-http document on this machine, which is how the
 * emulator suite serves one. A Functions param cannot be set by a committed
 * test — the emulator reads params only from git-ignored `.env` files — so
 * the switch is a document, the way `aiEmulator` is; no rule names it, so no
 * client reaches it, and in the cloud it is never read.
 */
export async function clientDocumentsMayBeLocal(store: Firestore): Promise<boolean> {
  if (!runsInEmulator()) return false;
  const switches = await store.collection('assistantsEmulator').doc('cimd').get();
  return switches.get('allowLoopback') === true;
}
