import { onDocumentCreated } from 'firebase-functions/v2/firestore';

import { aiRuntime, imageRuntime } from '../ai/ai_runtime';
import { HOUSEHOLDS } from '../household/documents';
import { pushService } from '../notifications/push_service';
import { readFlag } from '../shared/feature_flags';
import { db } from '../shared/firestore';
import { objectStore } from '../shared/storage';
import { settleAvatarCreation } from './avatar_creation';
import { AVATAR_CREATIONS } from './avatar_refs';
import { waitForImageTurn } from './image_pacing';

export const onAvatarCreation = onDocumentCreated(
  {
    document: `${HOUSEHOLDS}/{householdId}/${AVATAR_CREATIONS}/{creationId}`,
    timeoutSeconds: 300,
    memory: '512MiB',
  },
  async (event) => {
    const { householdId, creationId } = event.params;
    const store = db();
    await settleAvatarCreation(
      {
        store,
        objects: objectStore(),
        sender: pushService(),
        text: await aiRuntime(store),
        image: await imageRuntime(store),
        flagOn: await readFlag(store, 'avatarCreations'),
        now: new Date(),
        ...(process.env['FUNCTIONS_EMULATOR'] === 'true'
          ? {}
          : { imageTurn: (): Promise<void> => waitForImageTurn(store) }),
      },
      householdId,
      creationId,
    );
  },
);
