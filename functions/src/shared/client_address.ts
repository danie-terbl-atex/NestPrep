/**
 * The address a request came from, as the one subject an unauthenticated
 * endpoint can be rate-limited by (accounts ADR-0006).
 *
 * Behind Firebase Hosting and Google's front end the socket address is the
 * proxy's, so the first `x-forwarded-for` hop is the caller's. It is spoofable
 * by anybody who sends the header themselves — which is why every limit keyed
 * on it also has a global ceiling that no header changes. It is only ever used
 * hashed, never stored or logged (ENG-22).
 */
export interface AddressedRequest {
  readonly ip?: string | undefined;
  readonly headers: Readonly<Record<string, string | string[] | undefined>>;
}

export function clientAddress(request: AddressedRequest | undefined): string {
  if (request === undefined) return 'unknown';
  const forwarded = request.headers['x-forwarded-for'];
  const first = (Array.isArray(forwarded) ? forwarded[0] : forwarded)?.split(',')[0]?.trim();
  if (first !== undefined && first !== '') return first;
  return request.ip ?? 'unknown';
}

/**
 * The address an endpoint behind Hosting counts a browser by: the hop left of the
 * right-most `X-Forwarded-For` hop. Measured in the cloud on 2026-10-29,
 * Hosting replaces whatever the caller sent with `client, proxy`, where the
 * proxy is one of a rotating pool of Google addresses, so the right-most hop
 * would pool every member behind whichever proxy carried them. A call made
 * straight to the Function's own URL, which cannot be closed while Hosting
 * rewrites to it, keeps the caller's header with the real address appended,
 * so there the hop counted can be forged; the overall ceilings hold either
 * way. `req.ip` is not used: the Functions Framework enables Express's
 * `trust proxy`, which makes it the left-most hop. Only ever used hashed,
 * never stored or logged (ENG-22).
 */
export function callerAddress(request: AddressedRequest): string {
  const forwarded = request.headers['x-forwarded-for'];
  const hops = (Array.isArray(forwarded) ? forwarded.join(',') : (forwarded ?? ''))
    .split(',')
    .map((hop) => hop.trim())
    .filter((hop) => hop !== '');
  return hops.at(-2) ?? hops.at(-1) ?? request.ip ?? 'unknown';
}
