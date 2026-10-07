import { APIError, TypeSafeClient } from '@typesafe-ai/sdk';

import type { DecisionModel, DecisionReply, DecisionRequest } from './decision_model';
import { ModelCallError } from './generative_model';

const JEV_TIMEOUT_MS = 25_000;

export class JevDecisionModel implements DecisionModel {
  private readonly client: TypeSafeClient;

  constructor(
    apiKey: string,
    readonly name: string,
  ) {
    this.client = new TypeSafeClient({
      apiKey,
      defaultModel: name,
      timeout: JEV_TIMEOUT_MS,
      logLevel: 'off',
    });
  }

  async decide(request: DecisionRequest): Promise<DecisionReply> {
    try {
      const reply = await this.client.systemOne({
        model: this.name,
        state: request.state,
        questions: request.questions,
      });
      return {
        answers: reply.answers,
        usage: { inputTokens: reply.usage.input_tokens, outputTokens: reply.usage.output_tokens },
        modelVersion: reply.model,
      };
    } catch (error) {
      if (error instanceof APIError) {
        const kind = error.status >= 500 || error.status === 429 ? 'transient' : 'permanent';
        throw new ModelCallError(kind, `jev answered ${String(error.status)}`);
      }
      throw new ModelCallError('transient', error instanceof Error ? error.name : 'jev failed');
    }
  }
}
