import { GoogleAuth } from 'google-auth-library';

import { StoreUnreachable } from '../verified_purchase';

/**
 * Where the Play Developer API's bearer token comes from — behind an
 * interface so the adapter is tested with a canned one (BE-09).
 */
export interface AccessTokenSource {
  token(): Promise<string>;
}

export const ANDROID_PUBLISHER_SCOPE = 'https://www.googleapis.com/auth/androidpublisher';

/**
 * The Functions runtime's own service account, through application-default
 * credentials — no key file anywhere (subscriptions ADR-0001, ENG-18). It
 * works once Daniel invites that service account into the Play Console with
 * the *View financial data* and *Manage orders and subscriptions*
 * permissions; until then Google answers 401 or 403, and the purchase is
 * kept on the phone to be verified again.
 */
export class ApplicationDefaultTokenSource implements AccessTokenSource {
  private readonly auth = new GoogleAuth({ scopes: [ANDROID_PUBLISHER_SCOPE] });

  async token(): Promise<string> {
    try {
      const token = await this.auth.getAccessToken();
      if (typeof token !== 'string' || token === '') throw new StoreUnreachable('no token');
      return token;
    } catch (error) {
      if (error instanceof StoreUnreachable) throw error;
      // No credentials on this machine (the emulator), or the metadata server
      // would not answer: the store cannot be asked, and nothing is lost.
      if (error instanceof Error) throw new StoreUnreachable('no credentials');
      throw error;
    }
  }
}
