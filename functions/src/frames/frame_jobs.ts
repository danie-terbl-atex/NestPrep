import { z } from 'zod';

import { FRAME_PHOTO_ID } from './frame_schemas';

/**
 * What a frame may do with a home-care job and its helper's shift
 * (photo-frames ADR-0020), pure so it is tested where it lives (`BE-14`).
 */

export const HOME_CARE_JOBS = 'homeCareJobs';
export const HOME_CARE_SHIFTS = 'homeCareShifts';
export const JOB_EVENTS = 'events';
export const BEFORE_PHOTO = 'before';

/** The statuses a job is still the helper's to hand in from (home-care ADR-0001). */
export const WITH_HELPER_STATUSES: readonly string[] = ['assigned', 'inProgress', 'sentBack'];
export const HANDED_IN_STATUSES: readonly string[] = ['submitted', 'approved'];

export const MARK_LIMIT = 20;
export const MARK_POINT_LIMIT = 200;

const markShape = z.object({ points: z.array(z.number()).catch([]) });

/** What a hand-in from the wall reads of a job before it writes. */
export const frameJobShape = z.object({
  helperId: z.string(),
  status: z.string(),
  dueDate: z.string(),
  steps: z.array(z.object({ id: z.string() }).loose()).catch([]),
  revision: z.number().int().nonnegative(),
});
export type FrameJob = z.infer<typeof frameJobShape>;

export const frameJobPhotoShape = z.object({
  helperId: z.string(),
  dueDate: z.string(),
  beforePhoto: z.object({ photoId: z.literal(BEFORE_PHOTO) }).loose(),
});

/**
 * The parent's circles as the wall draws them: each a flat `x, y, …` list,
 * every value 0–1 of the photo to three places, capped as the rules cap
 * them. Anything that is not a stroke is left off.
 */
export function frameMarks(stored: unknown): number[][] {
  if (!Array.isArray(stored)) return [];
  return stored.slice(0, MARK_LIMIT).flatMap((mark) => {
    const parsed = markShape.safeParse(mark);
    if (!parsed.success) return [];
    const points = parsed.data.points
      .slice(0, MARK_POINT_LIMIT * 2)
      .map((value) => Math.round(Math.min(1, Math.max(0, value)) * 1000) / 1000);
    const whole = points.slice(0, points.length - (points.length % 2));
    return whole.length < 4 || whole.some((value) => !Number.isFinite(value)) ? [] : [whole];
  });
}

/** Whether a job's picture can be asked for by the job's own id. */
export function hasFramePhoto(jobId: string, beforePhoto: unknown): boolean {
  return (
    FRAME_PHOTO_ID.test(jobId) &&
    z
      .object({ photoId: z.literal(BEFORE_PHOTO) })
      .loose()
      .safeParse(beforePhoto).success
  );
}

/** The fields a hand-in without an after photo changes (home-care ADR-0008). */
export function handInFields(job: FrameJob): {
  doneStepIds: string[];
  afterPhoto: null;
  status: 'submitted';
  revision: number;
} {
  return {
    doneStepIds: job.steps.map((step) => step.id),
    afterPhoto: null,
    status: 'submitted',
    revision: job.revision + 1,
  };
}

/** The helper's shift as the wall says it. */
export type FrameShift =
  | { readonly on: false }
  | { readonly on: true; readonly since: string; readonly sinceDate: string };
