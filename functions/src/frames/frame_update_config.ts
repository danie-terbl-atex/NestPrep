import { defineString } from 'firebase-functions/params';

import { type FrameServiceWifi, serviceWifiOf } from './frame_update_policy';

export const frameServiceWifiSsid = defineString('FRAME_SERVICE_WIFI_SSID', { default: '' });
export const frameServiceWifiPsk = defineString('FRAME_SERVICE_WIFI_PSK', { default: '' });

export function frameServiceWifi(): FrameServiceWifi | null {
  return serviceWifiOf(frameServiceWifiSsid.value(), frameServiceWifiPsk.value());
}
