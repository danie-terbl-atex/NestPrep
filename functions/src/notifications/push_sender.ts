import type { NotificationCategory } from './notification_contract';

/**
 * The one door to a push service (notifications ADR-0001, BE-09). Everything
 * else in this feature speaks to this interface, so the delivery rules — who,
 * when, what happens to a dead token — are tested against a recording fake,
 * and a push service that is down never fails a write it does not own.
 */
export interface PushMessage {
  readonly tokens: readonly string[];
  readonly category: NotificationCategory;
  readonly title: string;
  readonly body: string;
  /** Ids and kinds only (`PUSH_DATA_KEYS`). */
  readonly data: Readonly<Record<string, string>>;
}

export interface PushOutcome {
  /** How many phones accepted it. */
  readonly delivered: number;
  /** Tokens the service says belong to no phone any more — to forget. */
  readonly invalidTokens: readonly string[];
  /** Whether trying again later could work (a timeout, an outage). */
  readonly retryable: boolean;
}

export interface PushSender {
  send(message: PushMessage): Promise<PushOutcome>;
}
