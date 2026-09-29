import { FcmPushSender } from './fcm_push_sender';
import type { PushSender } from './push_sender';

/**
 * The push service every deployed Function sends through — one instance, made
 * on first use so importing a Function never starts the messaging SDK. Tests
 * never reach it: they hand their own `PushSender` to the job bodies.
 */
let shared: PushSender | undefined;

export function pushService(): PushSender {
  shared ??= new FcmPushSender();
  return shared;
}
