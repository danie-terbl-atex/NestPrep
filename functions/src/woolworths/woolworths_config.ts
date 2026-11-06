import { defineSecret, defineString } from 'firebase-functions/params';

import { configured } from '../shared/configured_value';

export const woolworthsSessionKey = defineSecret('WOOLWORTHS_SESSION_KEY');
export const woolworthsCognitoClientId = defineString('WOOLWORTHS_COGNITO_CLIENT_ID', {
  default: '',
});
export const woolworthsCognitoRegion = defineString('WOOLWORTHS_COGNITO_REGION', { default: '' });
export const woolworthsApiId = defineString('WOOLWORTHS_API_ID', { default: '' });
export const woolworthsSha1Password = defineString('WOOLWORTHS_SHA1_PASSWORD', { default: '' });
export const woolworthsAppVersion = defineString('WOOLWORTHS_APP_VERSION', { default: '' });
export const woolworthsOs = defineString('WOOLWORTHS_OS', { default: '' });
export const woolworthsOsVersion = defineString('WOOLWORTHS_OS_VERSION', { default: '' });
export const woolworthsDeviceVersion = defineString('WOOLWORTHS_DEVICE_VERSION', { default: '' });
export const woolworthsDeviceModel = defineString('WOOLWORTHS_DEVICE_MODEL', { default: '' });
export const woolworthsUserAgent = defineString('WOOLWORTHS_USER_AGENT', { default: '' });

export const WOOLWORTHS_SECRETS = [woolworthsSessionKey];

export interface WoolworthsCognito {
  readonly clientId: string;
  readonly region: string;
}

export interface WoolworthsAppIdentity {
  readonly apiId: string;
  readonly sha1Password: string;
  readonly appVersion: string;
  readonly os: string;
  readonly osVersion: string;
  readonly deviceVersion: string;
  readonly deviceModel: string;
  readonly userAgent: string;
}

const REGION = /^[a-z]{2}(-[a-z]+)+-\d$/;

export function woolworthsCognito(): WoolworthsCognito | null {
  const clientId = configured(woolworthsCognitoClientId.value());
  const region = configured(woolworthsCognitoRegion.value());
  if (clientId === null || region === null || !REGION.test(region)) return null;
  return { clientId, region };
}

export function woolworthsAppIdentity(): WoolworthsAppIdentity | null {
  const apiId = configured(woolworthsApiId.value());
  const sha1Password = configured(woolworthsSha1Password.value());
  const appVersion = configured(woolworthsAppVersion.value());
  const os = configured(woolworthsOs.value());
  const osVersion = configured(woolworthsOsVersion.value());
  const deviceVersion = configured(woolworthsDeviceVersion.value());
  const deviceModel = configured(woolworthsDeviceModel.value());
  const userAgent = configured(woolworthsUserAgent.value());
  if (
    apiId === null ||
    sha1Password === null ||
    appVersion === null ||
    os === null ||
    osVersion === null ||
    deviceVersion === null ||
    deviceModel === null ||
    userAgent === null
  ) {
    return null;
  }
  return { apiId, sha1Password, appVersion, os, osVersion, deviceVersion, deviceModel, userAgent };
}
