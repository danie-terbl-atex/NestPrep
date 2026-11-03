import { lookup } from 'node:dns/promises';
import { BlockList, isIP } from 'node:net';

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
    (address) => !isPrivateAddress(address) || (allowLoopback && isLoopbackAddress(address)),
  );
}

/** Whether [address] is loopback, in any spelling of it, v4 or v6. */
export function isLoopbackAddress(address: string): boolean {
  const v4 = asIpv4(address);
  if (v4 !== null) return LOOPBACK.check(v4, 'ipv4');
  return isIP(bare(address)) === 6 && LOOPBACK.check(bare(address), 'ipv6');
}

/**
 * Loopback, private, link-local, carrier-grade NAT, documentation, benchmark,
 * reserved, multicast, broadcast or unspecified — anything that is not the
 * public internet. An IPv6 address that carries an IPv4 one (mapped, the
 * SIIT form, NAT64, IPv4-compatible, 6to4) is judged by the IPv4 address it
 * carries, because that is where a dual-stack socket or a translator sends
 * it. A string that is not an address is private: unknown is refused.
 */
export function isPrivateAddress(address: string): boolean {
  const v4 = asIpv4(address);
  if (v4 !== null) return PRIVATE_V4.check(v4, 'ipv4');
  const v6 = bare(address);
  return isIP(v6) !== 6 || PRIVATE_V6.check(v6, 'ipv6');
}

const LOOPBACK = new BlockList();
LOOPBACK.addSubnet('127.0.0.0', 8, 'ipv4');
LOOPBACK.addAddress('::1', 'ipv6');

/**
 * Two lists, because a `BlockList` matches an IPv4 address against its IPv6
 * rules too, through the mapped form. The v6 list therefore never names
 * `::ffff:0:0/96` or `::/96` — those addresses are judged as IPv4 first.
 */
const PRIVATE_V4 = new BlockList();
for (const [network, prefix] of [
  ['0.0.0.0', 8],
  ['10.0.0.0', 8],
  ['100.64.0.0', 10],
  ['127.0.0.0', 8],
  ['169.254.0.0', 16],
  ['172.16.0.0', 12],
  ['192.0.0.0', 24],
  ['192.0.2.0', 24],
  ['192.88.99.0', 24],
  ['192.168.0.0', 16],
  ['198.18.0.0', 15],
  ['198.51.100.0', 24],
  ['203.0.113.0', 24],
  ['224.0.0.0', 4],
  ['240.0.0.0', 4],
] as const) {
  PRIVATE_V4.addSubnet(network, prefix, 'ipv4');
}
const PRIVATE_V6 = new BlockList();
for (const [network, prefix] of [
  ['::', 128],
  ['::1', 128],
  ['64:ff9b:1::', 48],
  ['100::', 64],
  ['2001::', 23],
  ['2001:db8::', 32],
  ['3fff::', 20],
  ['5f00::', 16],
  ['fc00::', 7],
  ['fe80::', 10],
  ['fec0::', 10],
  ['ff00::', 8],
] as const) {
  PRIVATE_V6.addSubnet(network, prefix, 'ipv6');
}

/** An address without the brackets of a URL host or the zone of a link-local one. */
function bare(address: string): string {
  return address
    .replace(/^\[|\]$/g, '')
    .replace(/%.*$/, '')
    .toLowerCase();
}

/** The IPv4 address [address] is, or carries inside an IPv6 one; null for any other. */
function asIpv4(address: string): string | null {
  const plain = bare(address);
  if (isIP(plain) === 4) return plain;
  if (isIP(plain) !== 6) return null;
  const words = hextets(plain);
  const zero = (from: number, to: number): boolean => words.slice(from, to).every((w) => w === 0);
  const [w0 = 0, w1 = 0, w2 = 0, , w4 = 0, w5 = 0, w6 = 0, w7 = 0] = words;
  const dotted = (high: number, low: number): string =>
    [high >> 8, high & 0xff, low >> 8, low & 0xff].join('.');
  if (zero(0, 5) && w5 === 0xffff) return dotted(w6, w7);
  if (zero(0, 4) && w4 === 0xffff && w5 === 0) return dotted(w6, w7);
  if (w0 === 0x64 && w1 === 0xff9b && zero(2, 6)) return dotted(w6, w7);
  if (zero(0, 6) && (w6 !== 0 || w7 > 1)) return dotted(w6, w7);
  if (w0 === 0x2002) return dotted(w1, w2);
  return null;
}

/** The eight 16-bit words of a valid IPv6 address, a trailing dotted quad included. */
function hextets(address: string): number[] {
  const quad = /(\d+)\.(\d+)\.(\d+)\.(\d+)$/.exec(address);
  const text =
    quad === null
      ? address
      : `${address.slice(0, quad.index)}${((Number(quad[1]) << 8) | Number(quad[2])).toString(
          16,
        )}:${((Number(quad[3]) << 8) | Number(quad[4])).toString(16)}`;
  const [head = '', tail] = text.split('::');
  const words = (part: string): number[] =>
    part === '' ? [] : part.split(':').map((word) => parseInt(word, 16));
  const front = words(head);
  const back = tail === undefined ? [] : words(tail);
  return [...front, ...Array<number>(8 - front.length - back.length).fill(0), ...back];
}
