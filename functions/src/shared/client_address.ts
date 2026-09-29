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
