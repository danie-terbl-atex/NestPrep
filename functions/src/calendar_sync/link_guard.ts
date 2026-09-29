import { lookup } from 'node:dns/promises';
import { isIP } from 'node:net';

/**
 * A pasted calendar link is fetched by a Function running inside Google's
 * network, so the link is checked before every request — including each
 * redirect — to be sure it leads somewhere public (calendar ADR-0003). Without
 * this, "add a calendar link" is a way to make NestPrep read its own metadata
 * server.
 */

/** Resolves a host name to its addresses. Injected so tests need no DNS. */
export type HostResolver = (host: string) => Promise<string[]>;

export const dnsResolver: HostResolver = async (host) =>
  (await lookup(host, { all: true, verbatim: true })).map((entry) => entry.address);

/**
 * The link as NestPrep will fetch it: `webcal://` and `webcals://` become
 * `https://`; anything that is not https — or http when [allowPlainHttp], which
 * is only ever the emulator — is refused, as is a link carrying a password.
 */
export function normaliseCalendarLink(raw: string, allowPlainHttp: boolean): URL | null {
  const rewritten = raw.trim().replace(/^webcals?:\/\//i, 'https://');
  let url: URL;
  try {
    url = new URL(rewritten);
  } catch (error) {
    if (error instanceof TypeError) return null;
    throw error;
  }
  const schemeAllowed = url.protocol === 'https:' || (allowPlainHttp && url.protocol === 'http:');
  if (!schemeAllowed || url.hostname === '' || url.username !== '' || url.password !== '') {
    return null;
  }
  return url;
}

/**
 * Whether every address [host] resolves to is on the public internet.
 * [allowLoopback] lets the emulator's own tests serve a calendar from
 * 127.0.0.1; it is never true in the cloud.
 */
export async function isPublicHost(
  host: string,
  resolve: HostResolver,
  allowLoopback: boolean,
): Promise<boolean> {
  const bare = host.replace(/^\[|\]$/g, '');
  let addresses: string[];
  if (isIP(bare) !== 0) {
    addresses = [bare];
  } else {
    try {
      addresses = await resolve(bare);
    } catch (error) {
      if (error instanceof Error) return false;
      throw error;
    }
  }
  if (addresses.length === 0) return false;
  return addresses.every(
    (address) => !isPrivateAddress(address) || (allowLoopback && isLoopback(address)),
  );
}

function isLoopback(address: string): boolean {
  return address === '::1' || address.startsWith('127.');
}

/** Loopback, private, link-local, carrier-grade NAT, multicast or unspecified. */
export function isPrivateAddress(address: string): boolean {
  const lower = address.toLowerCase();
  const mapped = /^::ffff:(\d+\.\d+\.\d+\.\d+)$/.exec(lower);
  if (mapped?.[1] !== undefined) return isPrivateAddress(mapped[1]);
  if (isIP(lower) === 6) {
    return (
      lower === '::' ||
      lower === '::1' ||
      /^f[cd][0-9a-f]{2}:/.test(lower) ||
      /^fe[89ab][0-9a-f]:/.test(lower) ||
      /^ff[0-9a-f]{2}:/.test(lower)
    );
  }
  const octets = lower.split('.').map(Number);
  if (octets.length !== 4 || octets.some((octet) => Number.isNaN(octet))) return true;
  const [a = 0, b = 0] = octets;
  return (
    a === 0 ||
    a === 10 ||
    a === 127 ||
    (a === 100 && b >= 64 && b <= 127) ||
    (a === 169 && b === 254) ||
    (a === 172 && b >= 16 && b <= 31) ||
    (a === 192 && b === 168) ||
    a >= 224
  );
}
