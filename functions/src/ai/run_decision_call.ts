import { refuseAi } from './ai_refusals';
import { isFeatureOn, type AiFeature, type AiSettings } from './ai_settings';
import { callForDecisions, type Answers } from './decision_call';
import type { DecisionModel, DecisionRequest } from './decision_model';
import { spendAiCall, type AiResult, type AiSpend, type SpendDependencies } from './run_ai_call';
import { StructuredCallFailure } from './structured_call';

export interface DecisionDependencies extends SpendDependencies {
  readonly model: DecisionModel;
}

export interface DecisionCall extends AiSpend {
  readonly request: DecisionRequest;
}

/** A decision charged to the household's monthly calls, like any model call (foundation ADR-0021). */
export function runDecisionCall(
  deps: DecisionDependencies,
  call: DecisionCall,
): Promise<AiResult<Answers>> {
  return spendAiCall(deps, call, deps.model.name, () => callForDecisions(deps.model, call.request));
}

/** A decision under the switches but outside the monthly cap (foundation ADR-0021 §4). */
export async function askDecisions(
  deps: { readonly model: DecisionModel; readonly settings: AiSettings },
  feature: AiFeature,
  request: DecisionRequest,
): Promise<Answers> {
  if (!isFeatureOn(deps.settings, feature)) throw refuseAi('aiSwitchedOff');
  try {
    return (await callForDecisions(deps.model, request)).value;
  } catch (error) {
    if (!(error instanceof StructuredCallFailure)) throw error;
    throw refuseAi(error.kind === 'declined' ? 'aiDeclined' : 'aiUnavailable');
  }
}
