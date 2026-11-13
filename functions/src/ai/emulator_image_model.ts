import { readFile } from 'node:fs/promises';
import { resolve } from 'node:path';

import type { Firestore } from 'firebase-admin/firestore';
import { z } from 'zod';

import { AI_EMULATOR } from './emulator_model';
import { ModelCallError } from './generative_model';
import type { ImageAspectRatio, ImageModel, ImageReply, ImageRequest } from './image_model';

/**
 * The image model the Functions emulator uses instead of Vertex (lunch-box
 * ADR-0015): nothing leaves the machine and nothing is billed. Every picture
 * is a bundled JPEG of the asked shape, unless `aiEmulator/{feature}.failWith`
 * says to fail the way Vertex can.
 */
export const EMULATOR_PHOTO_PATH = resolve(__dirname, '../../assets/emulator_lunch_photo.jpg');

export const EMULATOR_PICTURES: Readonly<Record<ImageAspectRatio, string>> = {
  '4:3': EMULATOR_PHOTO_PATH,
  '1:1': resolve(__dirname, '../../assets/emulator_avatar.jpg'),
  '16:9': resolve(__dirname, '../../assets/emulator_portrait.jpg'),
};

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
      bytes: await readFile(EMULATOR_PICTURES[request.aspectRatio]),
      mimeType: 'image/jpeg',
      modelVersion: this.name,
    };
  }
}
