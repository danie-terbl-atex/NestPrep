import { onCall } from 'firebase-functions/v2/https';

import { parseInput } from '../household/parse_input';
import { db } from '../shared/firestore';
import { readLinkedFrame } from './frame_access';
import { type FrameDay, assembleFrameDay } from './frame_day';
import { readFrameSources } from './frame_reads';
import { FRAME_DAY_PER_CREDENTIAL, FRAME_DEVICE_OPTIONS } from './frame_policy';
import { getFrameDayInput } from './frame_schemas';

export type GetFrameDayResult = { status: 'unlinked' } | FrameDay;

const UNLINKED: GetFrameDayResult = { status: 'unlinked' };

/**
 * A linked frame reads its household's day (photo-frames ADR-0001): one call,
 * every panel it shows, assembled in the household's zone. The frame is
 * unlinked the moment family deletes its record — the next read finds no
 * frame, retires the credential and says so.
 */
export const getFrameDay = onCall(
  FRAME_DEVICE_OPTIONS,
  async (request): Promise<GetFrameDayResult> => {
    const { secret } = parseInput(getFrameDayInput, request.data);
    const store = db();
    const linked = await readLinkedFrame(store, secret, FRAME_DAY_PER_CREDENTIAL);
    if (linked === null) return UNLINKED;
    const { frame, home, clock } = linked;

    const sources = await readFrameSources(store, home, frame.panels, clock.date, frame.groceries);
    return assembleFrameDay({
      householdName: linked.householdName,
      frameName: frame.name,
      panels: frame.panels,
      screensaver: frame.screensaver,
      today: clock.date,
      localMinute: clock.minute,
      ...sources,
    });
  },
);
