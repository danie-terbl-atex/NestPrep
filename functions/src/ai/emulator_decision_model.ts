import type { Firestore } from 'firebase-admin/firestore';
import type { Question } from '@typesafe-ai/sdk';
import { z } from 'zod';

import type { DecisionModel, DecisionReply, DecisionRequest } from './decision_model';
import { AI_EMULATOR } from './emulator_model';
import { ModelCallError } from './generative_model';

const cannedDecisions = z.object({
  answers: z.record(z.string(), z.unknown()).optional(),
  failWith: z.enum(['transient', 'blocked', 'permanent']).optional(),
});

/**
 * Answers from `aiEmulator/{label}.answers`, question by question; anything
 * not canned is a sure yes or the first choice, so a local run builds a week.
 */
export class EmulatorDecisionModel implements DecisionModel {
  readonly name = 'emulator-decisions';

  constructor(private readonly store: Firestore) {}

  async decide(request: DecisionRequest): Promise<DecisionReply> {
    const snapshot = await this.store.collection(AI_EMULATOR).doc(request.label).get();
    const canned = cannedDecisions.safeParse(snapshot.data() ?? {});
    const usage = { inputTokens: 10, outputTokens: 1 };
    if (!canned.success) throw new ModelCallError('permanent', 'canned decisions unreadable');
    if (canned.data.failWith !== undefined) {
      throw new ModelCallError(canned.data.failWith, 'canned failure', usage);
    }
    const answers = Object.fromEntries(
      Object.entries(request.questions).map(([id, question]) => [
        id,
        canned.data.answers?.[id] ?? defaultAnswer(question),
      ]),
    );
    return { answers, usage, modelVersion: this.name };
  }
}

function defaultAnswer(question: Question): unknown {
  switch (question.type) {
    case 'noul':
      return { type: 'noul', noul: 1 };
    case 'choice': {
      const [first = ''] = Object.keys(question.criteria);
      return { type: 'choice', choice: first, confidence: 1, probabilities: { [first]: 1 } };
    }
    case 'score':
      return { type: 'score', score: 0, confidence: 1, probabilities: { 0: 1 } };
  }
}
