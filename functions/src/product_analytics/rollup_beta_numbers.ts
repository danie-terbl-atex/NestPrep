import { onSchedule } from 'firebase-functions/v2/scheduler';
import { logger } from 'firebase-functions/v2';

import { db } from '../shared/firestore';
import { LAUNCH_TIME_ZONE } from './iso_week';
import { rollupWeek, weeksToRollUp } from './weekly_rollup';

/**
 * Recounts the beta numbers every night (product-analytics ADR-0001, `BE-15`).
 *
 * Daily rather than weekly, so this week's numbers exist while the week is
 * still running and one missed run costs a day rather than a week. Every run
 * overwrites what the last one wrote, so a late or doubled run is harmless.
 * Region, instances, memory and timeout come from the global options like every
 * other function here.
 */
export const rollupBetaNumbers = onSchedule(
  { schedule: 'every day 03:00', timeZone: LAUNCH_TIME_ZONE },
  async () => {
    const now = new Date();
    const store = db();
    const weeks = weeksToRollUp(now);
    for (const week of weeks) {
      await rollupWeek(store, week, now);
    }
    logger.info('beta numbers recounted', { weeks });
  },
);
