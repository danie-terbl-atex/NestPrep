/**
 * Home care's job photos: the committed placeholder JPEGs, where they go in
 * Storage (the object name is the photo id, with the uploader's uid in its
 * metadata as the rules require), and the marks ringing the grime in
 * `images/before.jpg`.
 */
import { readFileSync } from 'node:fs';
import { resolve } from 'node:path';

import { WHO, uidOf } from './cast.mjs';

const { mom, helper } = WHO;

/**
 * The grime spots in `images/before.jpg` as centre and radius in pixels, so
 * the marks ring what is actually dirty.
 */
const GRIME = [
  [180, 260, 70],
  [420, 330, 90],
  [300, 560, 110],
  [150, 650, 60],
];

/** A closed ring round a spot, as the 0–1 point list a mark stores. */
function ring(x, y, radius) {
  const points = [];
  for (let step = 0; step <= 24; step += 1) {
    const angle = (step / 24) * 2 * Math.PI;
    points.push(
      Math.round(((x + Math.cos(angle) * radius * 1.1) / PHOTO.width) * 1000) / 1000,
      Math.round(((y + Math.sin(angle) * radius * 1.1) / PHOTO.height) * 1000) / 1000,
    );
  }
  return points;
}

const IMAGES = resolve(import.meta.dirname, 'images');
export const PHOTO = { width: 600, height: 800 };

/** One ring per grime spot. */
export function grimeMarks() {
  return GRIME.map(([x, y, radius]) => ({ points: ring(x, y, radius) }));
}

export async function uploadPhoto(ctx, jobId, photoId, file) {
  await ctx.bucket
    .file(`households/${ctx.cast.householdId}/homeCareJobs/${jobId}/${photoId}`)
    .save(readFileSync(resolve(IMAGES, file)), {
      contentType: 'image/jpeg',
      resumable: false,
      metadata: { metadata: { uploadedByUid: uidOf(photoId === 'before' ? mom : helper) } },
    });
}
