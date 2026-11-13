import { existsSync } from 'node:fs';
import { resolve } from 'node:path';

import { describe, expect, it } from 'vitest';

import {
  ACCESSORIES,
  MOMENTS,
  NESTLINGS,
  NESTLING_FACES,
  NESTLING_STAGES,
  nestlingAssetId,
} from '../../../src/avatars/avatar_catalogue';

/** The generated catalogue against the pictures shipped beside it (avatars ADR-0002). */

const ASSETS = resolve(__dirname, '../../../assets/avatars');
const NESTLING_IDS = NESTLINGS.flatMap((nestling) =>
  NESTLING_STAGES.map((stage) => nestlingAssetId(nestling.name, stage)),
);

describe('the avatar catalogue', () => {
  it('ships a picture for every asset id', () => {
    const ids = [...NESTLING_IDS, ...ACCESSORIES.map((a) => a.id), ...MOMENTS.map((m) => m.id)];
    expect(ids.filter((id) => !existsSync(resolve(ASSETS, `${id}.webp`)))).toEqual([]);
  });

  it('anchors a face on every Nestling picture and on nothing else', () => {
    expect(Object.keys(NESTLING_FACES).sort()).toEqual([...NESTLING_IDS].sort());
  });

  it('keeps every face on the picture, wide enough to wear something', () => {
    for (const [id, face] of Object.entries(NESTLING_FACES)) {
      expect(face.x, id).toBeGreaterThan(0.2);
      expect(face.x, id).toBeLessThan(0.8);
      expect(face.y, id).toBeGreaterThan(0.1);
      expect(face.y, id).toBeLessThan(0.7);
      expect(face.w, id).toBeGreaterThan(0.15);
      expect(face.w, id).toBeLessThan(0.65);
    }
  });
});
