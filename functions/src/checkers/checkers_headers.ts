import type { CheckersAppIdentity } from './checkers_config';
import type { CheckersSession, StoreContext } from './checkers_api';

/**
 * The headers the Sixty60 Android app sends, so a call from here reads like
 * the app's own (the Checkers build contract). Which call takes which set is
 * the app's choice, not ours; the OSS clients captured it and it is copied
 * here unchanged.
 */
const CHANNEL = 'super-app';
const USER_AGENT = 'okhttp/4.12.0';

export type Headers = Record<string, string>;

/** What every call carries: the app, the install, and JSON. */
export function appHeaders(app: CheckersAppIdentity, deviceId: string): Headers {
  return {
    accept: 'application/json',
    'content-type': 'application/json',
    channel: CHANNEL,
    'app-version': app.appVersion,
    appversion: app.appVersionCode,
    'device-id': deviceId,
    'user-agent': USER_AGENT,
  };
}

/** The free app token call, which takes no body and no app version. */
export function bootstrapHeaders(deviceId: string): Headers {
  return {
    accept: 'application/json',
    channel: CHANNEL,
    'device-id': deviceId,
    'user-agent': USER_AGENT,
  };
}

/** The login calls: the app token as the bearer, and the DSL's key when it is the DSL. */
export function loginHeaders(
  app: CheckersAppIdentity,
  deviceId: string,
  appToken: string,
  isDsl: boolean,
): Headers {
  return {
    ...appHeaders(app, deviceId),
    authorization: `Bearer ${appToken}`,
    ...(isDsl ? { 'x-api-key': app.apiKey } : {}),
  };
}

/** Shoprite's `/users`: the member's token in its own header, with the key — no bearer. */
export function identityHeaders(
  app: CheckersAppIdentity,
  deviceId: string,
  sessionToken: string,
): Headers {
  return { ...appHeaders(app, deviceId), access_token: sessionToken, 'x-api-key': app.apiKey };
}

/** The customer profile: the app's profile token as the bearer; the session is in the path. */
export function profileHeaders(app: CheckersAppIdentity, deviceId: string): Headers {
  return { ...appHeaders(app, deviceId), authorization: `Bearer ${app.profileToken}` };
}

/** Catalogue and cart calls as the member: the session and the stores it shops at. */
export function sessionHeaders(
  app: CheckersAppIdentity,
  deviceId: string,
  session: CheckersSession,
  stores: readonly StoreContext[],
): Headers {
  const storeIds = stores.map((store) => store.storeId);
  return {
    ...appHeaders(app, deviceId),
    authorization: `Bearer ${session.token}`,
    'channel-os': app.appVersion,
    'istio-appversion': app.appVersionCode,
    'customer-id': session.uuid,
    userid: session.userId,
    'aws-cf-cd-storeid': storeIds.join(','),
    storeids: JSON.stringify(storeIds),
    'istio-storeids': JSON.stringify(storeIds),
  };
}
