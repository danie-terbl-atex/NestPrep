import { logger } from 'firebase-functions/v2';
import { onRequest } from 'firebase-functions/v2/https';

import { callerAddress } from '../shared/client_address';
import { db } from '../shared/firestore';
import { consumeRateLimit, isWithinRateLimit } from '../shared/rate_limit';
import { HOSTING_REGION } from '../shared/region';
import { premiumEmailPepper, premiumPepper } from './premium_config';
import { answerPremiumWeb, routeOf } from './premium_web_answer';

export const premiumWeb = onRequest(
  { region: HOSTING_REGION, invoker: 'public', secrets: [premiumEmailPepper] },
  async (req, res) => {
    res.setHeader('Cache-Control', 'no-store');
    res.setHeader('Pragma', 'no-cache');
    const store = db();
    const now = new Date();
    try {
      const reply = await answerPremiumWeb(
        {
          store,
          pepper: premiumPepper,
          address: callerAddress(req),
          now,
          consume: (rule, subject) => consumeRateLimit(store, rule, subject, now),
          isWithin: (rule, subject) => isWithinRateLimit(store, rule, subject, now),
        },
        { method: req.method, path: req.path, body: req.body },
      );
      logger.info('premium web answered', {
        route: routeOf(req.path),
        status: reply.status,
        outcome: reply.body['error'] ?? reply.body['result'] ?? 'ok',
      });
      res.status(reply.status).json(reply.body);
    } catch (error) {
      logger.error('premium web failed', {
        route: routeOf(req.path),
        error: error instanceof Error ? error.message : String(error),
      });
      res.status(503).json({ error: 'unavailable' });
    }
  },
);
