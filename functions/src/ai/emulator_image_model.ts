import { readFile } from 'node:fs/promises';
import { resolve } from 'node:path';

import type { Firestore } from 'firebase-admin/firestore';
import { z } from 'zod';

import { AI_EMULATOR } from './emulator_model';
import { ModelCallError } from './generative_model';
import type { ImageModel, ImageReply, ImageRequest } from './image_model';

/**
 * The image model the Functions emulator uses instead of Vertex (lunch-box
 * ADR-0015): nothing leaves the machine and nothing is billed. Every picture
 * is the same bundled JPEG, unless `aiEmulator/{feature}.failWith` says to
 * fail the way Vertex can.
 */
export const EMULATOR_PHOTO_PATH = resolve(__dirname, '../../assets/emulator_lunch_photo.jpg');

const cannedImage = z.object({
  failWith: z.enum(['transient', 'timeout', 'blocked', 'permanent']).optional(),
});

export class EmulatorImageModel implements ImageModel {
  readonly name = 'emulator-image';

  constructor(private readonly store: Firestore) {}

  async generate(request: ImageRequest): Promise<ImageReply> {
    const feature = request.labels['feature'] ?? 'unknown';
    const snapshot = await this.store.collection(AI_EMULATOR).doc(feature).get();
    const canned = cannedImage.safeParse(snapshot.data() ?? {});
    if (!canned.success) throw new ModelCallError('permanent', 'canned image unreadable');
    if (canned.data.failWith !== undefined) {
      throw new ModelCallError(canned.data.failWith, 'canned failure');
    }
    return {
      bytes: await readFile(EMULATOR_PHOTO_PATH),
      mimeType: 'image/jpeg',
      modelVersion: this.name,
    };
  }
}
