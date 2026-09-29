import { X509Certificate, verify } from 'node:crypto';

import { z } from 'zod';

/**
 * Verifies a JWS the App Store signed — a transaction, a renewal, a
 * notification — and returns its payload, still unparsed (subscriptions
 * ADR-0001). It is done here, with Node's own crypto, rather than by a
 * library, because it is forty lines and the rules are Apple's published
 * ones:
 *
 * 1. the header is ES256 and carries a three-certificate `x5c` chain;
 * 2. the chain's root is byte-for-byte a root we trust (Apple Root CA - G3);
 * 3. each certificate is issued and signed by the next, and in date;
 * 4. the intermediate and the leaf carry Apple's marker extensions
 *    (1.2.840.113635.100.6.2.1 and 1.2.840.113635.100.6.11.1), so no other
 *    certificate Apple's root ever signed can sign a receipt;
 * 5. the signature over `header.payload` verifies with the leaf's key.
 *
 * What it does not do is ask Apple's OCSP responder whether the leaf has been
 * revoked; that is written down in the ADR as an accepted gap.
 */
export class SignedPayloadInvalid extends Error {
  constructor(readonly why: string) {
    super(`signed payload invalid: ${why}`);
    this.name = 'SignedPayloadInvalid';
  }
}

export interface SignatureTrust {
  /** DER certificates a chain may end in. Production passes Apple's root only. */
  readonly roots: readonly Buffer[];
  readonly now: Date;
}

const header = z.object({
  alg: z.literal('ES256'),
  x5c: z.array(z.string().min(1)).length(3),
});

// The marker extensions' OIDs, DER-encoded with their tag and length.
const INTERMEDIATE_MARKER = Buffer.from('060a2a864886f76364060201', 'hex');
const LEAF_MARKER = Buffer.from('060a2a864886f76364060b01', 'hex');

const MAX_JWS_LENGTH = 64 * 1024;

export function verifySignedPayload(jws: string, trust: SignatureTrust): unknown {
  if (jws.length > MAX_JWS_LENGTH) throw new SignedPayloadInvalid('too long');
  const [encodedHeader, encodedPayload, encodedSignature, ...rest] = jws.split('.');
  if (
    encodedHeader === undefined ||
    encodedPayload === undefined ||
    encodedSignature === undefined ||
    rest.length > 0
  ) {
    throw new SignedPayloadInvalid('not a compact JWS');
  }
  const parsedHeader = header.safeParse(decodeJson(encodedHeader));
  if (!parsedHeader.success) throw new SignedPayloadInvalid('unexpected header');

  const [leaf, intermediate, root] = parsedHeader.data.x5c.map(certificateOf);
  if (leaf === undefined || intermediate === undefined || root === undefined) {
    throw new SignedPayloadInvalid('short chain');
  }
  checkChain({ leaf, intermediate, root }, trust);

  const isSigned = verify(
    'sha256',
    Buffer.from(`${encodedHeader}.${encodedPayload}`),
    { key: leaf.publicKey, dsaEncoding: 'ieee-p1363' },
    Buffer.from(encodedSignature, 'base64url'),
  );
  if (!isSigned) throw new SignedPayloadInvalid('bad signature');
  return decodeJson(encodedPayload);
}

interface Chain {
  readonly leaf: X509Certificate;
  readonly intermediate: X509Certificate;
  readonly root: X509Certificate;
}

function checkChain({ leaf, intermediate, root }: Chain, trust: SignatureTrust): void {
  if (!trust.roots.some((trusted) => trusted.equals(root.raw))) {
    throw new SignedPayloadInvalid('untrusted root');
  }
  const isLinked =
    intermediate.checkIssued(root) &&
    intermediate.verify(root.publicKey) &&
    leaf.checkIssued(intermediate) &&
    leaf.verify(intermediate.publicKey);
  if (!isLinked) throw new SignedPayloadInvalid('broken chain');
  for (const certificate of [leaf, intermediate, root]) {
    const from = Date.parse(certificate.validFrom);
    const to = Date.parse(certificate.validTo);
    const at = trust.now.getTime();
    if (!(at >= from && at <= to)) throw new SignedPayloadInvalid('certificate out of date');
  }
  if (!intermediate.raw.includes(INTERMEDIATE_MARKER) || !leaf.raw.includes(LEAF_MARKER)) {
    throw new SignedPayloadInvalid('not an App Store signing certificate');
  }
}

function certificateOf(base64: string): X509Certificate {
  try {
    return new X509Certificate(Buffer.from(base64, 'base64'));
  } catch (error) {
    if (error instanceof Error) throw new SignedPayloadInvalid('unreadable certificate');
    throw error;
  }
}

function decodeJson(part: string): unknown {
  try {
    return JSON.parse(Buffer.from(part, 'base64url').toString('utf8')) as unknown;
  } catch (error) {
    if (error instanceof SyntaxError) throw new SignedPayloadInvalid('not JSON');
    throw error;
  }
}
