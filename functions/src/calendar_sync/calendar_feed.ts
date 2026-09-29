import type { Firestore } from 'firebase-admin/firestore';
import { onRequest } from 'firebase-functions/v2/https';
import { logger } from 'firebase-functions/v2';
import { z } from 'zod';

import { db } from '../shared/firestore';
import { householdRef } from '../household/documents';
import { hashFeedToken } from './feed_link';
import { type FeedEvent, storedEvent, writeFeed } from './feed_writer';
import { feedTokenRef } from './sync_documents';
import { addDays, knownZoneOr, wallClockOf } from './zoned_time';

/**
 * The household's calendar as a subscribable ICS feed (calendar ADR-0003). The
 * token is the only credential, so an unknown one is a plain 404 that says
 * nothing about why, and the token is never logged (ENG-22).
 */
const EVENT_LIMIT = 500;
const EXCEPTION_LIMIT = 2_000;
const EXCEPTIONS_DAYS_BACK = 90;

const tokenShape = z.object({ householdId: z.string() });
const householdShape = z.object({ name: z.string(), timeZone: z.string() });
const exceptionShape = z.object({ eventId: z.string(), occurrenceDate: z.string() });

export const calendarFeed = onRequest(async (req, res) => {
  if (req.method !== 'GET' && req.method !== 'HEAD') {
    res.status(405).send('Method not allowed');
    return;
  }
  const token = typeof req.query['token'] === 'string' ? req.query['token'] : '';
  const store = db();
  const body = /^[A-Za-z0-9_-]{32,64}$/.test(token) ? await feedFor(store, token) : null;
  if (body === null) {
    res.status(404).send('Not found');
    return;
  }
  res.setHeader('Content-Type', 'text/calendar; charset=utf-8');
  res.setHeader('Cache-Control', 'private, max-age=300');
  res.status(200).send(body);
});

async function feedFor(store: Firestore, token: string): Promise<string | null> {
  const mapping = tokenShape.safeParse(
    (await feedTokenRef(store, hashFeedToken(token)).get()).data(),
  );
  if (!mapping.success) return null;
  const { householdId } = mapping.data;
  const household = householdShape.safeParse((await householdRef(store, householdId).get()).data());
  if (!household.success) return null;

  const zone = knownZoneOr(household.data.timeZone);
  const now = new Date();
  const since = addDays(wallClockOf(now, zone).date, -EXCEPTIONS_DAYS_BACK);
  const [events, exceptions] = await Promise.all([
    householdRef(store, householdId).collection('events').limit(EVENT_LIMIT).get(),
    householdRef(store, householdId)
      .collection('eventExceptions')
      .where('occurrenceDate', '>=', since)
      .limit(EXCEPTION_LIMIT)
      .get(),
  ]);

  const skipped: Record<string, string[] | undefined> = {};
  for (const doc of exceptions.docs) {
    const exception = exceptionShape.safeParse(doc.data());
    if (!exception.success) continue;
    (skipped[exception.data.eventId] ??= []).push(exception.data.occurrenceDate);
  }
  const feedEvents: FeedEvent[] = events.docs.flatMap((doc) => {
    const event = storedEvent.safeParse(doc.data());
    return event.success ? [{ id: doc.id, event: event.data, skipped: skipped[doc.id] ?? [] }] : [];
  });
  logger.info('calendar feed served', { householdId, events: feedEvents.length });
  return writeFeed({ calendarName: household.data.name, zone, events: feedEvents, now });
}
