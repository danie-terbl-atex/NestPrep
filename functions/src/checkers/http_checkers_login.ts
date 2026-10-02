import type { HttpClient } from '../shared/http_client';
import {
  CheckersRefused,
  CheckersUnavailable,
  type CheckersLogin,
  type CheckersSession,
  type LinkedAccount,
  type OtpRoute,
  type PendingOtp,
  type StoreContext,
} from './checkers_api';
import type { CheckersAppIdentity } from './checkers_config';
import {
  appHeaders,
  bootstrapHeaders,
  identityHeaders,
  loginHeaders,
  profileHeaders,
} from './checkers_headers';
import { CHECKERS_HOSTS, askCheckers, isSuccess, readReply } from './checkers_request';
import {
  appTokenReply,
  defaultAddressCoordinates,
  identityReply,
  otpSentReply,
  otpVerifiedReply,
  profileReply,
  sixtyMinuteStores,
  storeContextsReply,
} from './checkers_wire';

/** Checkers' own session lifetime when a verify does not say (the contract's hour). */
const DEFAULT_LIFETIME_SECONDS = 3600;

/** A lifetime this short cannot be used before it lapses. */
const SHORTEST_USABLE_SECONDS = 60;

/**
 * Linking a member's Checkers account by SMS code, as the Sixty60 app does it
 * (the Checkers build contract): a free app token, the code sent through the
 * app's backend-for-frontend — or Shoprite's identity service when that one
 * will not — then the code verified where it was sent, and the three
 * identifiers and the stores read back.
 */
export class HttpCheckersLogin implements CheckersLogin {
  constructor(
    private readonly http: HttpClient,
    private readonly app: CheckersAppIdentity,
  ) {}

  async requestOtp(mobile: string, deviceId: string): Promise<PendingOtp> {
    const appToken = await this.appToken(deviceId);
    try {
      const reference = await this.sendCode('bff', mobile, appToken, deviceId);
      if (reference !== null) return { mobile, reference, route: 'bff' };
    } catch (error) {
      // The BFF is the app's first choice, not the only one: when it is down,
      // Shoprite's own service is asked below.
      if (!(error instanceof CheckersUnavailable)) throw error;
    }
    const reference = await this.sendCode('dsl', mobile, appToken, deviceId);
    if (reference === null) throw new CheckersRefused();
    return { mobile, reference, route: 'dsl' };
  }

  async verifyOtp(pending: PendingOtp, code: string, deviceId: string): Promise<LinkedAccount> {
    const appToken = await this.appToken(deviceId);
    const reply = await askCheckers(
      this.http,
      `${CHECKERS_HOSTS[pending.route]}/otp/loginbymobile/verify`,
      {
        method: 'POST',
        headers: loginHeaders(this.app, deviceId, appToken, pending.route === 'dsl'),
        body: JSON.stringify({
          target: { type: 'SMS', identifier: pending.mobile, reference: pending.reference },
          otp: code,
        }),
      },
    );
    const verified = otpVerifiedReply.safeParse(reply.body);
    if (!isSuccess(reply) || !verified.success) throw new CheckersRefused();
    const lifetime = verified.data.response.expiresIn ?? DEFAULT_LIFETIME_SECONDS;
    if (lifetime <= SHORTEST_USABLE_SECONDS) throw new CheckersUnavailable('lifetime');
    const token = verified.data.response.accessToken;
    const identity = await this.identity(token, deviceId);
    const { userId, storeContexts } = await this.profile(identity.customerId, token, deviceId);
    return {
      session: { token, userId, ...identity },
      expiresInSeconds: lifetime,
      storeContexts,
    };
  }

  /** The app-level token: not a person's, free, and good for a day. */
  private async appToken(deviceId: string): Promise<string> {
    const reply = await askCheckers(this.http, `${CHECKERS_HOSTS.bff}/token/dsl`, {
      method: 'POST',
      headers: bootstrapHeaders(deviceId),
    });
    return readReply(appTokenReply, reply).access_token;
  }

  /** The code's reference, or null when this service would not send one. */
  private async sendCode(
    route: OtpRoute,
    mobile: string,
    appToken: string,
    deviceId: string,
  ): Promise<string | null> {
    const reply = await askCheckers(
      this.http,
      `${CHECKERS_HOSTS[route]}/users/loginbymobile?mobileNumber=${encodeURIComponent(mobile)}`,
      { method: 'GET', headers: loginHeaders(this.app, deviceId, appToken, route === 'dsl') },
    );
    const sent = otpSentReply.safeParse(reply.body);
    return isSuccess(reply) && sent.success ? sent.data.response.reference : null;
  }

  private async identity(
    token: string,
    deviceId: string,
  ): Promise<Pick<CheckersSession, 'uuid' | 'customerId'>> {
    const reply = await askCheckers(this.http, `${CHECKERS_HOSTS.dsl}/users`, {
      method: 'GET',
      headers: identityHeaders(this.app, deviceId, token),
    });
    const { user } = readReply(identityReply, reply).response;
    return { uuid: user.uuid, customerId: user.customerId };
  }

  /** Sixty60's id for the customer, and the stores that deliver to their address. */
  private async profile(
    customerId: string,
    token: string,
    deviceId: string,
  ): Promise<{ userId: string; storeContexts: StoreContext[] }> {
    const url =
      `${CHECKERS_HOSTS.auth}/customers/${encodeURIComponent(customerId)}` +
      `/customer-profile/v2/${encodeURIComponent(token)}`;
    const reply = await askCheckers(this.http, url, {
      method: 'GET',
      headers: profileHeaders(this.app, deviceId),
    });
    const profile = readReply(profileReply, reply).userProfile;
    const stores = sixtyMinuteStores(profile.storeContexts);
    if (stores.length > 0) return { userId: profile.id, storeContexts: stores };
    const coordinates = defaultAddressCoordinates(profile.addresses);
    return {
      userId: profile.id,
      storeContexts: coordinates === null ? [] : await this.storesAt(coordinates, deviceId),
    };
  }

  private async storesAt(
    coordinates: { latitude: number; longitude: number },
    deviceId: string,
  ): Promise<StoreContext[]> {
    const reply = await askCheckers(this.http, `${CHECKERS_HOSTS.catalog}/api/v3/store-contexts`, {
      method: 'POST',
      headers: appHeaders(this.app, deviceId),
      body: JSON.stringify(coordinates),
    });
    // An address no store serves is answered 400: no stores, not an outage.
    if (reply.status === 400) return [];
    return sixtyMinuteStores(readReply(storeContextsReply, reply).items);
  }
}
