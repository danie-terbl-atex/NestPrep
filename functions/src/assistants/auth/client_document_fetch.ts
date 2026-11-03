import { lookup as dnsLookup, type LookupAddress } from 'node:dns';
import { get as httpGet, type IncomingMessage } from 'node:http';
import { get as httpsGet } from 'node:https';
import { isIP, type LookupFunction } from 'node:net';

import { isLoopbackAddress, isPrivateAddress } from '../../calendar_sync/link_guard';

/**
 * Fetches a client's metadata document (assistants ADR-0002) — a URL that
 * anybody on the internet can name as their `client_id`, fetched from inside
 * Google's network. So the address is checked as the socket connects, not
 * before: a host that resolves somewhere public for the check and somewhere
 * private for the connection (DNS rebinding) is caught, because there is only
 * one resolution and it is the one checked. A host that is an IP address is
 * refused outright — a client id names a domain, and Node connects to a
 * literal without any lookup to check — except loopback under the emulator
 * escape. No redirect is followed, the body stops at 5 KB, and the whole
 * fetch at 3 seconds.
 */
export type ClientDocumentFetch = (url: URL) => Promise<string>;

export const CLIENT_DOCUMENT_MAX_BYTES = 5 * 1024;
export const CLIENT_DOCUMENT_TIMEOUT_MS = 3_000;

export class ClientDocumentUnavailable extends Error {
  constructor(readonly reason: string) {
    super(`client document unavailable: ${reason}`);
    this.name = 'ClientDocumentUnavailable';
  }
}

export interface ClientDocumentFetchOptions {
  /** Plain http and loopback addresses, for the emulator suite's local server only. */
  readonly allowLocal: boolean;
  readonly timeoutMs?: number;
}

export function clientDocumentFetch(options: ClientDocumentFetchOptions): ClientDocumentFetch {
  const timeoutMs = options.timeoutMs ?? CLIENT_DOCUMENT_TIMEOUT_MS;
  const permitted = (address: string): boolean =>
    !isPrivateAddress(address) || (options.allowLocal && isLoopbackAddress(address));

  return (url) =>
    new Promise((resolve, reject) => {
      const fail = (reason: string): void => {
        reject(new ClientDocumentUnavailable(reason));
      };
      const secure = url.protocol === 'https:';
      if (!secure && !(options.allowLocal && url.protocol === 'http:')) {
        fail('scheme');
        return;
      }
      const literal = url.hostname.replace(/^\[|\]$/g, '');
      if (isIP(literal) !== 0 && !(options.allowLocal && isLoopbackAddress(literal))) {
        fail('address');
        return;
      }

      const request = (secure ? httpsGet : httpGet)(
        url,
        {
          lookup: checkedLookup(permitted),
          headers: { Accept: 'application/json' },
        },
        (response) => {
          readCapped(response).then(resolve, (error: unknown) => {
            fail(error instanceof ClientDocumentUnavailable ? error.reason : 'read');
          });
        },
      );
      const timer = setTimeout(() => {
        request.destroy(new ClientDocumentUnavailable('timeout'));
      }, timeoutMs);
      request.on('close', () => {
        clearTimeout(timer);
      });
      request.on('error', (error) => {
        fail(error instanceof ClientDocumentUnavailable ? error.reason : 'unreachable');
      });
    });
}

function readCapped(response: IncomingMessage): Promise<string> {
  return new Promise((resolve, reject) => {
    if (response.statusCode !== 200) {
      response.resume();
      reject(new ClientDocumentUnavailable(`status ${String(response.statusCode)}`));
      return;
    }
    const chunks: Buffer[] = [];
    let size = 0;
    response.on('data', (chunk: Buffer) => {
      size += chunk.length;
      if (size > CLIENT_DOCUMENT_MAX_BYTES) {
        response.destroy();
        reject(new ClientDocumentUnavailable('too large'));
        return;
      }
      chunks.push(chunk);
    });
    response.on('end', () => {
      resolve(Buffer.concat(chunks).toString('utf8'));
    });
    response.on('error', () => {
      reject(new ClientDocumentUnavailable('read'));
    });
  });
}

/**
 * A `lookup` for the socket that resolves every address and refuses the
 * connection unless all of them are permitted — answering in whichever shape
 * the caller asked for, since Node's happy-eyeballs connect asks for all.
 */
function checkedLookup(permitted: (address: string) => boolean): LookupFunction {
  return (hostname, options, callback) => {
    dnsLookup(hostname, { all: true, verbatim: true }, (error, addresses: LookupAddress[]) => {
      if (error !== null) {
        callback(error, '', 0);
        return;
      }
      const first = addresses[0];
      if (first === undefined || !addresses.every((entry) => permitted(entry.address))) {
        callback(new ClientDocumentUnavailable('address'), '', 0);
        return;
      }
      if (options.all === true) {
        callback(null, addresses);
        return;
      }
      callback(null, first.address, first.family);
    });
  };
}
