import { addDays } from '../calendar_sync/zoned_time';
import { db } from '../shared/firestore';
import { frameJpegEndpoint } from './frame_jpeg';
import { parsed } from './frame_documents';
import { BEFORE_PHOTO, HOME_CARE_JOBS, frameJobPhotoShape } from './frame_jobs';
import { readFramePremium } from './frame_lunch_photos';
import { FRAME_JOB_PHOTO_PER_CREDENTIAL, FRAME_OVERDUE_DAYS } from './frame_policy';

/**
 * The photo a parent took for one of the helper's jobs (photo-frames
 * ADR-0020): only a job of the frame's own helper, due inside the window the
 * day reads, so a frame with no helper, or another helper's job, is `missing`.
 */
export const getFrameJobPhoto = frameJpegEndpoint(
  FRAME_JOB_PHOTO_PER_CREDENTIAL,
  async ({ frame, home, clock }, id) => {
    const helperId = frame.panels.helperMemberId;
    if (helperId === null) return null;
    if (!(await readFramePremium(db(), home))) return null;
    const job = parsed(
      frameJobPhotoShape,
      (await home.collection(HOME_CARE_JOBS).doc(id).get()).data(),
    );
    const shown =
      job !== null &&
      job.helperId === helperId &&
      job.dueDate <= clock.date &&
      job.dueDate >= addDays(clock.date, -FRAME_OVERDUE_DAYS);
    return shown ? `${home.path}/${HOME_CARE_JOBS}/${id}/${BEFORE_PHOTO}` : null;
  },
);
