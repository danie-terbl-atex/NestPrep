import type { Firestore } from 'firebase-admin/firestore';

import { applicationDefaultTokens } from './access_token';
import { aiImageLocation, aiImageModel, aiLocation, aiModel, currentProject } from './ai_config';
import { AI_SETTINGS_COLLECTION, AI_SETTINGS_DOCUMENT, readAiSettings } from './ai_settings';
import { EmulatorImageModel } from './emulator_image_model';
import { EmulatorModel } from './emulator_model';
import { FirestoreUsageLedger } from './firestore_usage_ledger';
import type { GenerativeModel } from './generative_model';
import type { ImageModel } from './image_model';
import { ImagenModel } from './imagen_model';
import type { AiDependencies, ImageDependencies, SpendDependencies } from './run_ai_call';
import { VertexModel } from './vertex_model';

/**
 * The real dependencies of an AI call, built per request so a change to the
 * kill switch in `appConfig/ai` bites on the very next call (foundation
 * ADR-0015). One small read per call is the price of an instant switch.
 */
export async function aiRuntime(store: Firestore): Promise<AiDependencies> {
  return { ...(await spendingIn(store)), model: modelFor(store) };
}

/** The same for a picture (lunch-box ADR-0015): the same switch, cap and ledger. */
export async function imageRuntime(store: Firestore): Promise<ImageDependencies> {
  return { ...(await spendingIn(store)), model: imageModelFor(store) };
}

async function spendingIn(store: Firestore): Promise<SpendDependencies> {
  const settings = await store.collection(AI_SETTINGS_COLLECTION).doc(AI_SETTINGS_DOCUMENT).get();
  return {
    ledger: new FirestoreUsageLedger(store),
    settings: readAiSettings(settings.data()),
    now: () => new Date(),
  };
}

function isEmulated(): boolean {
  return process.env['FUNCTIONS_EMULATOR'] === 'true';
}

/** Vertex in the cloud; the canned model under the emulator, which bills nothing. */
function modelFor(store: Firestore): GenerativeModel {
  if (isEmulated()) return new EmulatorModel(store);
  return new VertexModel({
    project: currentProject(),
    location: aiLocation.value(),
    model: aiModel.value(),
    tokens: applicationDefaultTokens,
  });
}

/** Imagen in the cloud; the bundled photo under the emulator. */
function imageModelFor(store: Firestore): ImageModel {
  if (isEmulated()) return new EmulatorImageModel(store);
  return new ImagenModel({
    project: currentProject(),
    location: aiImageLocation.value(),
    model: aiImageModel.value(),
    tokens: applicationDefaultTokens,
  });
}
