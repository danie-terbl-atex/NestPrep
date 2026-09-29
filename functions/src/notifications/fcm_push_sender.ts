import { getMessaging, type BatchResponse, type Messaging } from 'firebase-admin/messaging';
import { logger } from 'firebase-functions/v2';

import { adminApp } from '../shared/admin_app';
import { ANDROID_CHANNELS } from './notification_contract';
import type { PushMessage, PushOutcome, PushSender } from './push_sender';

/**
 * Firebase Cloud Messaging, for Android and — through the APNs key uploaded
 * to the Firebase project — iOS (notifications ADR-0001). The only file that
 * knows FCM exists.
 *
 * Bounded (BE-19): a send that has not answered in ten seconds is treated as
 * an outage and tried again later, never waited on. Nothing here throws at a
 * caller: an unreachable FCM is an outcome, because a notification that cannot
 * be sent must not undo the thing it was about (BE-09).
 */
export const SEND_TIMEOUT_MS = 10_000;

/** FCM's words for "this token belongs to no phone". */
const DEAD_TOKEN_CODES = new Set([
  'messaging/registration-token-not-registered',
  'messaging/invalid-registration-token',
]);

/** FCM's words for "not now". */
const RETRYABLE_CODES = new Set([
  'messaging/internal-error',
  'messaging/server-unavailable',
  'messaging/unavailable',
  'messaging/quota-exceeded',
  'messaging/message-rate-exceeded',
]);

function withTimeout<T>(work: Promise<T>, ms: number): Promise<T> {
  let timer: NodeJS.Timeout | undefined;
  const timeout = new Promise<never>((_, reject) => {
    timer = setTimeout(() => {
      reject(new Error(`push send timed out after ${String(ms)} ms`));
    }, ms);
  });
  return Promise.race([work, timeout]).finally(() => {
    clearTimeout(timer);
  });
}

/** Reads a batch answer into the outcome delivery acts on. Pure, and tested. */
export function outcomeOf(tokens: readonly string[], response: BatchResponse): PushOutcome {
  const invalidTokens: string[] = [];
  let retryable = false;
  response.responses.forEach((answer, index) => {
    if (answer.success) return;
    const code = answer.error?.code ?? '';
    const token = tokens[index];
    if (DEAD_TOKEN_CODES.has(code) && token !== undefined) invalidTokens.push(token);
    if (RETRYABLE_CODES.has(code)) retryable = true;
  });
  return { delivered: response.successCount, invalidTokens, retryable };
}

export class FcmPushSender implements PushSender {
  constructor(private readonly messaging: () => Messaging = () => getMessaging(adminApp())) {}

  async send(message: PushMessage): Promise<PushOutcome> {
    const tokens = [...message.tokens];
    try {
      const response = await withTimeout(
        // Registration tokens, because that is what `firebase_messaging` hands the
        // app; FID targeting is Admin 14's preferred form and a later decision
        // (notifications ADR-0001, *What would make us revisit this*).
        // eslint-disable-next-line @typescript-eslint/no-deprecated -- tokens are what the Flutter SDK issues
        this.messaging().sendEachForMulticast({
          tokens,
          notification: { title: message.title, body: message.body },
          data: { ...message.data },
          android: {
            priority: 'high',
            notification: { channelId: ANDROID_CHANNELS[message.category] },
          },
          apns: { payload: { aps: { sound: 'default', threadId: message.category } } },
        }),
        SEND_TIMEOUT_MS,
      );
      return outcomeOf(tokens, response);
    } catch (error) {
      // An outage, a timeout or missing credentials: logged with the kind of
      // failure and never a token (ENG-22), and answered as "try later".
      logger.warn('push send failed', {
        category: message.category,
        reason: error instanceof Error ? error.message : 'unknown',
      });
      return { delivered: 0, invalidTokens: [], retryable: true };
    }
  }
}
