import type { Firestore } from 'firebase-admin/firestore';
import { z } from 'zod';

import {
  ModelCallError,
  type GenerativeModel,
  type ModelReply,
  type ModelRequest,
} from './generative_model';

/**
 * The model the Functions emulator uses instead of Vertex (foundation
 * ADR-0015): nothing leaves the machine, nothing is billed, and a test says
 * what the "model" answers.
 *
 * The answer for a feature is the `reply` field of `aiEmulator/{feature}`,
 * which an emulator test or the seed script writes with the admin SDK — no
 * client may read or write it, and it does not exist in the cloud. `failWith`
 * makes it fail the way Vertex can instead. The feature is the request's
 * `feature` label, so this needs no knowledge of any feature.
 */
export const AI_EMULATOR = 'aiEmulator';

const cannedReply = z.object({
  reply: z.string().optional(),
  failWith: z.enum(['transient', 'blocked', 'permanent']).optional(),
});

export class EmulatorModel implements GenerativeModel {
  readonly name = 'emulator';

  constructor(private readonly store: Firestore) {}

  async generate(request: ModelRequest): Promise<ModelReply> {
    const feature = request.labels['feature'] ?? 'unknown';
    const snapshot = await this.store.collection(AI_EMULATOR).doc(feature).get();
    const canned = cannedReply.safeParse(snapshot.data() ?? {});
    const usage = { inputTokens: 10, outputTokens: 10 };
    if (!canned.success) throw new ModelCallError('permanent', 'canned reply unreadable');
    if (canned.data.failWith !== undefined) {
      throw new ModelCallError(canned.data.failWith, 'canned failure', usage);
    }
    return { text: canned.data.reply ?? '{}', usage, modelVersion: this.name };
  }
}
