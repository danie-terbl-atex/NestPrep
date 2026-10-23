import { FORM_HEADERS, formBody, type HttpClient } from '../shared/http_client';
import {
  PnpRefused,
  PnpSessionExpired,
  PnpUnavailable,
  type PnpClient,
  type PnpLogin,
  type PnpTokens,
} from './pnp_api';
import { forgetPnpClient, readPnpClient } from './pnp_client_config';
import { askPnp, readPnpReply, type PnpReply } from './pnp_request';
import { oauthError, tokenReply, tokensOf } from './pnp_wire';

/** The website's registered redirect; the app's web view intercepts it and never loads it. */
export const PNP_REDIRECT_URI = 'https://www.pnp.co.za/oidc_login';

/** What PnP says when a code or a refresh token is no good. */
const SPENT_GRANTS = new Set(['invalid_grant', 'invalid_token']);

/**
 * PnP's OIDC token endpoint, as the website's client (add-to-pnp ADR-0003):
 * a login code with its PKCE verifier, or a refresh token, for the member's
 * tokens. Nothing here is logged; a token never leaves this class except in
 * the answer.
 */
export class HttpPnpLogin implements PnpLogin {
  constructor(
    private readonly http: HttpClient,
    private readonly now: () => Date = () => new Date(),
  ) {}

  client(): Promise<PnpClient> {
    return readPnpClient(this.http, this.now());
  }

  async exchangeCode(code: string, verifier: string): Promise<PnpTokens> {
    const reply = await this.token({
      grant_type: 'authorization_code',
      code,
      redirect_uri: PNP_REDIRECT_URI,
      code_verifier: verifier,
    });
    if (isSpentGrant(reply)) throw new PnpRefused();
    return tokensOf(readPnpReply(tokenReply, reply));
  }

  async refresh(refreshToken: string): Promise<PnpTokens> {
    const reply = await this.token({ grant_type: 'refresh_token', refresh_token: refreshToken });
    if (isSpentGrant(reply)) throw new PnpSessionExpired();
    return tokensOf(readPnpReply(tokenReply, reply));
  }

  private async token(fields: Record<string, string>): Promise<PnpReply> {
    const client = await this.client();
    const basic = Buffer.from(`${client.clientId}:${client.clientSecret}`).toString('base64');
    const reply = await askPnp(this.http, client.tokenEndpoint, {
      method: 'POST',
      headers: { ...FORM_HEADERS, Accept: 'application/json', Authorization: `Basic ${basic}` },
      body: formBody(fields),
    });
    if (reply.status === 401 && !isSpentGrant(reply)) {
      // The client itself was refused: PnP rotated it. Read it again next time.
      forgetPnpClient();
      throw new PnpUnavailable('client refused');
    }
    return reply;
  }
}

function isSpentGrant(reply: PnpReply): boolean {
  if (reply.status !== 400 && reply.status !== 401) return false;
  const parsed = oauthError.safeParse(reply.body);
  return parsed.success && SPENT_GRANTS.has(parsed.data.error);
}
