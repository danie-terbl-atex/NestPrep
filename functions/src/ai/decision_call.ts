import { z } from 'zod';

import type { DecisionModel, DecisionQuestions, DecisionRequest } from './decision_model';
import { ModelCallError, NO_USAGE, addUsage } from './generative_model';
import { StructuredCallFailure, type StructuredReply } from './structured_call';

export type Answers = Readonly<Record<string, unknown>>;

/** About 40k tokens at a pessimistic three characters a token, inside Jev's 64k budget. */
export const MAX_DECISION_REQUEST_CHARS = 120_000;

export async function callForDecisions(
  model: DecisionModel,
  request: DecisionRequest,
): Promise<StructuredReply<Answers>> {
  const batches = questionBatches(request.questions);
  const settled = await Promise.allSettled(
    batches.map((questions) => model.decide({ ...request, questions })),
  );
  let usage = NO_USAGE;
  let modelVersion = model.name;
  const answers: Record<string, unknown> = {};
  for (const outcome of settled) {
    if (outcome.status === 'rejected') {
      const error: unknown = outcome.reason;
      if (!(error instanceof ModelCallError)) throw error;
      throw new StructuredCallFailure(
        error.kind === 'blocked' ? 'declined' : 'unavailable',
        error.detail,
        addUsage(usage, error.usage),
        1,
      );
    }
    usage = addUsage(usage, outcome.value.usage);
    modelVersion = outcome.value.modelVersion;
    Object.assign(answers, outcome.value.answers);
  }
  const missing = Object.keys(request.questions).filter((id) => !(id in answers));
  if (missing.length > 0) {
    throw new StructuredCallFailure('unreadable', `${String(missing.length)} unanswered`, usage, 1);
  }
  return { value: answers, usage, attempts: 1, modelVersion };
}

export function questionBatches(questions: DecisionQuestions): DecisionQuestions[] {
  const batches: DecisionQuestions[] = [];
  let current: Record<string, DecisionQuestions[string]> = {};
  let size = 0;
  for (const [id, question] of Object.entries(questions)) {
    const questionSize = id.length + JSON.stringify(question).length;
    if (size > 0 && size + questionSize > MAX_DECISION_REQUEST_CHARS) {
      batches.push(current);
      current = {};
      size = 0;
    }
    current[id] = question;
    size += questionSize;
  }
  if (size > 0) batches.push(current);
  return batches;
}

const noulAnswer = z.object({ noul: z.number().min(0).max(1) });
const choiceAnswer = z.object({ choice: z.string() });

export function noulOf(answers: Answers, id: string): number | null {
  const parsed = noulAnswer.safeParse(answers[id]);
  return parsed.success ? parsed.data.noul : null;
}

export function choiceOf(answers: Answers, id: string): string | null {
  const parsed = choiceAnswer.safeParse(answers[id]);
  return parsed.success ? parsed.data.choice : null;
}
