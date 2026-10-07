import type { EntryType, Question } from '@typesafe-ai/sdk';

import type { ModelUsage } from './generative_model';

export type DecisionQuestions = Readonly<Record<string, Question>>;

export interface DecisionRequest {
  /** Names the canned answers under the emulator; never sent to the model. */
  readonly label: string;
  readonly state: EntryType;
  readonly questions: DecisionQuestions;
}

export interface DecisionReply {
  readonly answers: Readonly<Record<string, unknown>>;
  readonly usage: ModelUsage;
  readonly modelVersion: string;
}

export interface DecisionModel {
  readonly name: string;
  decide(request: DecisionRequest): Promise<DecisionReply>;
}
