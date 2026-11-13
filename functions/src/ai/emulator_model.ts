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
 *
 * `cycle` answers its replies in turn, one a call, so a developer meets every
 * path a feature has from the app.
 *
 * `live: true` on the document sends a feature in [LIVE_FEATURES] to the real
 * model on the developer's own sign-in (recipes ADR-0008 §11): a real page has
 * to be read by something real, and a document can't leak into `test:emulator`
 * the way an environment variable could.
 */
export const AI_EMULATOR = 'aiEmulator';
export const LIVE_FEATURES: readonly string[] = ['recipeImport', 'recipeDocument'];

const cannedReply = z.object({
  reply: z.string().optional(),
  failWith: z.enum(['transient', 'blocked', 'permanent']).optional(),
  cycle: z.array(z.string()).min(1).optional(),
});

export class EmulatorModel implements GenerativeModel {
  readonly name = 'emulator';

  constructor(
    private readonly store: Firestore,
    private readonly liveModel: () => GenerativeModel,
  ) {}

  async generate(request: ModelRequest, signal: AbortSignal): Promise<ModelReply> {
    const feature = request.labels['feature'] ?? 'unknown';
    const snapshot = await this.store.collection(AI_EMULATOR).doc(feature).get();
    if (snapshot.get('live') === true && LIVE_FEATURES.includes(feature)) {
      return this.liveModel().generate(request, signal);
    }
    const canned = cannedReply.safeParse(snapshot.data() ?? {});
    const usage = { inputTokens: 10, outputTokens: 10 };
    if (!canned.success) throw new ModelCallError('permanent', 'canned reply unreadable');
    if (canned.data.failWith !== undefined) {
      throw new ModelCallError(canned.data.failWith, 'canned failure', usage);
    }
    const text =
      canned.data.cycle === undefined
        ? (canned.data.reply ?? '{}')
        : await this.nextInCycle(feature, canned.data.cycle);
    return { text, usage, modelVersion: this.name };
  }

  private nextInCycle(feature: string, cycle: readonly string[]): Promise<string> {
    const ref = this.store.collection(AI_EMULATOR).doc(feature);
    return this.store.runTransaction(async (transaction) => {
      const turn: unknown = (await transaction.get(ref)).get('turn');
      const at = typeof turn === 'number' && Number.isInteger(turn) && turn >= 0 ? turn : 0;
      transaction.update(ref, { turn: at + 1 });
      return cycle[at % cycle.length] ?? '{}';
    });
  }
}
