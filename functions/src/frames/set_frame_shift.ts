import { FieldValue, Timestamp } from 'firebase-admin/firestore';
import { onCall } from 'firebase-functions/v2/https';

import { knownZoneOr, wallClockOf } from '../calendar_sync/zoned_time';
import { MEMBERS } from '../household/documents';
import { parseInput } from '../household/parse_input';
import { readFlag } from '../shared/feature_flags';
import { db } from '../shared/firestore';
import { readLinkedFrame } from './frame_access';
import { frameShiftSince } from './frame_day';
import { refuseFrame } from './frame_errors';
import { type FrameShift, HOME_CARE_SHIFTS } from './frame_jobs';
import { FRAME_DEVICE_OPTIONS, FRAME_SHIFT_PER_CREDENTIAL } from './frame_policy';
import { openShiftsOf } from './frame_reads';
import { setFrameShiftInput } from './frame_schemas';

export type SetFrameShiftResult = { status: 'unlinked' } | { status: 'linked'; shift: FrameShift };

const UNLINKED: SetFrameShiftResult = { status: 'unlinked' };

/**
 * The frame's helper clocks in or out at the wall (photo-frames ADR-0020,
 * home-care ADR-0007). The open shift is looked up inside the transaction, so
 * two taps, or a phone and a wall, never open two; asking for the state she
 * is already in changes nothing and answers it.
 */
export const setFrameShift = onCall(
  FRAME_DEVICE_OPTIONS,
  async (request): Promise<SetFrameShiftResult> => {
    const input = parseInput(setFrameShiftInput, request.data);
    const store = db();
    const linked = await readLinkedFrame(store, input.secret, FRAME_SHIFT_PER_CREDENTIAL);
    if (linked === null) return UNLINKED;
    const { frame, home, clock, timeZone } = linked;
    const helperId = frame.panels.helperMemberId;
    if (helperId === null) throw refuseFrame('helperNotFound');
    if (!(await readFlag(store, 'homeCareShifts'))) throw refuseFrame('shiftsOff');

    const shift = await store.runTransaction(async (transaction): Promise<FrameShift> => {
      const helper = await transaction.get(home.collection(MEMBERS).doc(helperId));
      if (!helper.exists) throw refuseFrame('helperNotFound');
      const opened = (await transaction.get(openShiftsOf(home, helperId))).docs;
      const open = opened[0];
      if (input.on) {
        if (open !== undefined) {
          const startedAt: unknown = open.get('startedAt');
          return frameShiftSince(
            startedAt instanceof Timestamp
              ? wallClockOf(startedAt.toDate(), knownZoneOr(timeZone ?? undefined))
              : clock,
          );
        }
        transaction.set(home.collection(HOME_CARE_SHIFTS).doc(), {
          helperId,
          status: 'open',
          startedAt: FieldValue.serverTimestamp(),
          startedBy: helperId,
          startedVia: 'frame',
          endedAt: null,
          endedBy: null,
          endedVia: null,
        });
        return frameShiftSince(clock);
      }
      for (const shift of opened) {
        transaction.update(shift.ref, {
          status: 'ended',
          endedAt: FieldValue.serverTimestamp(),
          endedBy: helperId,
          endedVia: 'frame',
        });
      }
      return { on: false };
    });
    return { status: 'linked', shift };
  },
);
