import type { Firestore } from 'firebase-admin/firestore';

import { applicationDefaultTokens } from './access_token';
import { aiLocation, aiModel, currentProject } from './ai_config';
import { AI_SETTINGS_COLLECTION, AI_SETTINGS_DOCUMENT, readAiSettings } from './ai_settings';
import { EmulatorModel } from './emulator_model';
import { FirestoreUsageLedger } from './firestore_usage_ledger';
import type { GenerativeModel } from './generative_model';
import type { AiDependencies } from './run_ai_call';
import { VertexModel } from './vertex_model';

/**
 * The real dependencies of an AI call, built per request so a change to the
 * kill switch in `appConfig/ai` bites on the very next call (foundation
 * ADR-0015). One small read per call is the price of an instant switch.
 */
export async function aiRuntime(store: Firestore): Promise<AiDependencies> {
  const settings = await store.collection(AI_SETTINGS_COLLECTION).doc(AI_SETTINGS_DOCUMENT).get();
  return {
    model: modelFor(store),
    ledger: new FirestoreUsageLedger(store),
    settings: readAiSettings(settings.data()),
    now: () => new Date(),
  };
}

/** Vertex in the cloud; the canned model under the emulator, which bills nothing. */
function modelFor(store: Firestore): GenerativeModel {
  if (process.env['FUNCTIONS_EMULATOR'] === 'true') return new EmulatorModel(store);
  return new VertexModel({
    project: currentProject(),
    location: aiLocation.value(),
    model: aiModel.value(),
    tokens: applicationDefaultTokens,
  });
}
