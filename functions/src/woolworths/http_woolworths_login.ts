import type { HttpClient } from '../shared/http_client';
import {
  WoolworthsSessionExpired,
  WoolworthsUnavailable,
  type WoolworthsLogin,
  type WoolworthsTokens,
} from './woolworths_api';
import type { WoolworthsCognito } from './woolworths_config';
import { askWoolworths, cognitoEndpoint, readWoolworthsReply } from './woolworths_request';
import { cognitoAuthReply, cognitoError, tokensOf } from './woolworths_wire';

const REFUSED_TOKEN = new Set([
  'NotAuthorizedException',
  'UserNotFoundException',
  'UserNotConfirmedException',
  'PasswordResetRequiredException',
]);

export class HttpWoolworthsLogin implements WoolworthsLogin {
  constructor(
    private readonly http: HttpClient,
    private readonly cognito: WoolworthsCognito,
  ) {}

  async refresh(refreshToken: string): Promise<WoolworthsTokens> {
    const reply = await askWoolworths(this.http, cognitoEndpoint(this.cognito.region), {
      method: 'POST',
      headers: {
        'Content-Type': 'application/x-amz-json-1.1',
        'X-Amz-Target': 'AWSCognitoIdentityProviderService.InitiateAuth',
      },
      body: JSON.stringify({
        AuthFlow: 'REFRESH_TOKEN_AUTH',
        ClientId: this.cognito.clientId,
        AuthParameters: { REFRESH_TOKEN: refreshToken },
      }),
    });
    if (reply.status >= 400 && reply.status < 500) {
      const error = cognitoError.safeParse(reply.body);
      const type = error.success ? (error.data.__type.split('#').pop() ?? '') : '';
      if (REFUSED_TOKEN.has(type)) throw new WoolworthsSessionExpired();
      throw new WoolworthsUnavailable(`cognito ${type === '' ? String(reply.status) : type}`);
    }
    return tokensOf(readWoolworthsReply(cognitoAuthReply, reply));
  }
}
