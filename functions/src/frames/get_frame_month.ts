import { onCall } from 'firebase-functions/v2/https';

import { parseInput } from '../household/parse_input';
import { db } from '../shared/firestore';
import { readLinkedFrame } from './frame_access';
import { refuseFrame } from './frame_errors';
import { type FrameMonth, assembleFrameMonth, monthGrid, monthInReach } from './frame_month';
import { readMonthSources } from './frame_reads';
import { FRAME_DEVICE_OPTIONS, FRAME_MONTH_PER_CREDENTIAL } from './frame_policy';
import { getFrameMonthInput } from './frame_schemas';

export type GetFrameMonthResult = { status: 'unlinked' } | FrameMonth;

const UNLINKED: GetFrameMonthResult = { status: 'unlinked' };

/**
 * A linked frame reads one month of its calendar, only while someone has the
 * month open on the wall (photo-frames ADR-0005), so the day's minute-by-minute
 * read never pays for it.
 */
export const getFrameMonth = onCall(
  FRAME_DEVICE_OPTIONS,
  async (request): Promise<GetFrameMonthResult> => {
    const { secret, month } = parseInput(getFrameMonthInput, request.data);
    const store = db();
    const linked = await readLinkedFrame(store, secret, FRAME_MONTH_PER_CREDENTIAL);
    if (linked === null) return UNLINKED;
    const today = linked.clock.date;
    if (!monthInReach(month, today)) throw refuseFrame('monthOutOfRange');

    const { from, to } = monthGrid(month);
    const sources = await readMonthSources(linked.home, linked.frame.panels, from, to);
    return assembleFrameMonth({ today, month, ...sources });
  },
);
