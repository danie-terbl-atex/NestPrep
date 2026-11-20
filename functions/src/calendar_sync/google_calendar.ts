import { z } from 'zod';

import type {
  AuthorizationRequest,
  CodeExchange,
  ExchangedAccount,
  FetchOutcome,
  OAuthCalendar,
} from './calendar_source';
import type { ExternalOccurrence, OccurrenceTime, SyncWindow } from './external_occurrence';
import {
  FORM_HEADERS,
  type HttpClient,
  type HttpResponse,
  HttpUnreachable,
  formBody,
  jsonOf,
} from '../shared/http_client';
import { addressOnIdToken, codeGrant, refreshGrant, requestTokens } from './oauth_tokens';
import type { GoogleClient } from './sync_config';

/**
 * Google Calendar, read-only, through its REST API (calendar ADR-0003, and
 * ADR-0007 for which calendars). The primary calendar and, where the
 * deployment has switched it on, every other one the account has ticked in
 * Google Calendar — a calendar shared with it included; repeating events are expanded by Google (`singleEvents=true`), each instance
 * with its own instant, computed in the event's own zone — so a weekly 07:30
 * keeps its time across a clocks change.
 */
export const GOOGLE_AUTHORIZE_URL = 'https://accounts.google.com/o/oauth2/v2/auth';
export const GOOGLE_TOKEN_URL = 'https://oauth2.googleapis.com/token';
export const GOOGLE_REVOKE_URL = 'https://oauth2.googleapis.com/revoke';
export const GOOGLE_CALENDAR_LIST_URL =
  'https://www.googleapis.com/calendar/v3/users/me/calendarList';
export const GOOGLE_SCOPES =
  'openid email https://www.googleapis.com/auth/calendar.events.readonly';
export const GOOGLE_LIST_SCOPE = 'https://www.googleapis.com/auth/calendar.calendarlist.readonly';

export function googleEventsUrl(calendarId: string): string {
  return `https://www.googleapis.com/calendar/v3/calendars/${encodeURIComponent(calendarId)}/events`;
}

const PRIMARY = 'primary';
export const GOOGLE_EVENTS_URL = googleEventsUrl(PRIMARY);

/** The primary and at most nine more, so one account cannot spend a whole run. */
export const MAX_CALENDARS = 10;

/** Holidays, birthdays and week numbers: Google's own calendars, nobody's plans. */
const GOOGLE_OWN_CALENDARS = '@group.v.calendar.google.com';

const RATE_LIMIT_REASONS = new Set(['rateLimitExceeded', 'userRateLimitExceeded', 'quotaExceeded']);

/** How far one sync will page: 4 pages of 250 is the 1,000 cap (ADR-0003). */
const PAGE_SIZE = 250;
const MAX_PAGES = 4;

const googleTime = z.object({
  dateTime: z.string().optional(),
  date: z.string().optional(),
});

const googleEvent = z.object({
  id: z.string(),
  status: z.string().optional(),
  summary: z.string().optional(),
  start: googleTime,
  end: googleTime,
  attendees: z
    .array(z.object({ self: z.boolean().optional(), responseStatus: z.string().optional() }))
    .optional(),
});

const eventsPage = z.object({
  items: z.array(z.unknown()).default([]),
  nextPageToken: z.string().optional(),
});

const calendarListEntry = z.object({
  id: z.string().min(1),
  primary: z.boolean().optional(),
  selected: z.boolean().optional(),
  deleted: z.boolean().optional(),
});

const calendarListPage = z.object({ items: z.array(z.unknown()).default([]) });

const refusal = z.object({
  error: z.object({ errors: z.array(z.object({ reason: z.string().optional() })).default([]) }),
});

export type GoogleEvent = z.infer<typeof googleEvent>;

type Failed = { kind: 'revoked' } | { kind: 'unreachable' };
type CalendarRead = { kind: 'read'; occurrences: ExternalOccurrence[] } | Failed;

export class GoogleCalendar implements OAuthCalendar {
  constructor(
    private readonly client: GoogleClient,
    private readonly http: HttpClient,
  ) {}

  authorizationUrl(request: AuthorizationRequest): string {
    const query = new URLSearchParams({
      client_id: this.client.clientId,
      redirect_uri: request.redirectUri,
      response_type: 'code',
      scope: this.client.otherCalendars ? `${GOOGLE_SCOPES} ${GOOGLE_LIST_SCOPE}` : GOOGLE_SCOPES,
      access_type: 'offline',
      // Without consent Google hands a returning account no refresh token.
      prompt: 'consent',
      include_granted_scopes: 'true',
      state: request.state,
      code_challenge: request.codeChallenge,
      code_challenge_method: 'S256',
    });
    return `${GOOGLE_AUTHORIZE_URL}?${query.toString()}`;
  }

  async exchangeCode(exchange: CodeExchange): Promise<ExchangedAccount | null> {
    const tokens = await requestTokens(
      this.http,
      { url: GOOGLE_TOKEN_URL, client: this.client },
      codeGrant(exchange.code, exchange.codeVerifier, exchange.redirectUri),
    );
    if (tokens.kind !== 'ok' || tokens.refreshToken === null) return null;
    return { refreshToken: tokens.refreshToken, accountLabel: addressOnIdToken(tokens.idToken) };
  }

  async fetchOccurrences(credential: string, window: SyncWindow): Promise<FetchOutcome> {
    const tokens = await requestTokens(
      this.http,
      { url: GOOGLE_TOKEN_URL, client: this.client },
      refreshGrant(credential),
    );
    if (tokens.kind !== 'ok') return tokens;

    const others = await this.otherCalendars(tokens.accessToken);
    if (others.kind !== 'calendars') return others;
    const [primary, ...shared] = await Promise.all(
      [PRIMARY, ...others.ids].map((id) => this.readCalendar(tokens.accessToken, id, window)),
    );
    if (primary === undefined || primary.kind !== 'read') return primary ?? { kind: 'unreachable' };

    const occurrences = [...primary.occurrences];
    for (const calendar of shared) {
      if (calendar.kind === 'unreachable') return calendar;
      // A calendar that was unshared between the list and the read is skipped.
      if (calendar.kind === 'read') occurrences.push(...calendar.occurrences);
    }
    return { kind: 'ok', occurrences, refreshedCredential: tokens.refreshToken };
  }

  async revoke(credential: string): Promise<void> {
    await this.http.send(GOOGLE_REVOKE_URL, {
      method: 'POST',
      headers: FORM_HEADERS,
      body: formBody({ token: credential }),
    });
  }

  /**
   * The calendars beside the primary that the account shows in Google
   * Calendar. A grant from before the list scope was asked for is refused
   * here, and reads its primary calendar as it always did.
   */
  private async otherCalendars(
    accessToken: string,
  ): Promise<{ kind: 'calendars'; ids: string[] } | Failed> {
    if (!this.client.otherCalendars) return { kind: 'calendars', ids: [] };
    const query = new URLSearchParams({ minAccessRole: 'reader', maxResults: '250' });
    const response = await this.get(`${GOOGLE_CALENDAR_LIST_URL}?${query.toString()}`, accessToken);
    if (response === null || isRateLimited(response)) return { kind: 'unreachable' };
    if (response.status === 401) return { kind: 'revoked' };
    if (response.status === 403) return { kind: 'calendars', ids: [] };
    if (response.status !== 200) return { kind: 'unreachable' };
    const parsed = calendarListPage.safeParse(jsonOf(response.body));
    if (!parsed.success) return { kind: 'unreachable' };
    const ids = parsed.data.items.flatMap((item) => {
      const entry = calendarListEntry.safeParse(item);
      if (!entry.success) return [];
      const { id, primary, selected, deleted } = entry.data;
      const shown = selected === true && primary !== true && deleted !== true;
      return shown && !id.endsWith(GOOGLE_OWN_CALENDARS) ? [id] : [];
    });
    return { kind: 'calendars', ids: ids.slice(0, MAX_CALENDARS - 1) };
  }

  private async readCalendar(
    accessToken: string,
    calendarId: string,
    window: SyncWindow,
  ): Promise<CalendarRead> {
    const occurrences: ExternalOccurrence[] = [];
    let pageToken: string | undefined;
    for (let page = 0; page < MAX_PAGES; page++) {
      const result = await this.page(accessToken, calendarId, window, pageToken);
      if (result.kind !== 'page') return result;
      occurrences.push(...result.occurrences);
      pageToken = result.next;
      if (pageToken === undefined) break;
    }
    return { kind: 'read', occurrences };
  }

  private async get(url: string, accessToken: string): Promise<HttpResponse | null> {
    try {
      return await this.http.send(url, {
        method: 'GET',
        headers: { Authorization: `Bearer ${accessToken}` },
      });
    } catch (error) {
      if (error instanceof HttpUnreachable) return null;
      throw error;
    }
  }

  private async page(
    accessToken: string,
    calendarId: string,
    window: SyncWindow,
    pageToken: string | undefined,
  ): Promise<
    { kind: 'page'; occurrences: ExternalOccurrence[]; next: string | undefined } | Failed
  > {
    const query = new URLSearchParams({
      singleEvents: 'true',
      orderBy: 'startTime',
      timeMin: window.timeMin.toISOString(),
      timeMax: window.timeMax.toISOString(),
      maxResults: String(PAGE_SIZE),
      ...(pageToken === undefined ? {} : { pageToken }),
    });
    const response = await this.get(
      `${googleEventsUrl(calendarId)}?${query.toString()}`,
      accessToken,
    );
    if (response === null || isRateLimited(response)) return { kind: 'unreachable' };
    if (response.status === 401 || response.status === 403) return { kind: 'revoked' };
    if (calendarId !== PRIMARY && (response.status === 404 || response.status === 410)) {
      return { kind: 'revoked' };
    }
    if (response.status !== 200) return { kind: 'unreachable' };
    const parsed = eventsPage.safeParse(jsonOf(response.body));
    if (!parsed.success) return { kind: 'unreachable' };
    return {
      kind: 'page',
      occurrences: parsed.data.items.flatMap((item) => {
        const event = googleEvent.safeParse(item);
        if (!event.success) return [];
        const occurrence = occurrenceFromGoogle(event.data);
        return occurrence === null ? [] : [occurrence];
      }),
      next: parsed.data.nextPageToken,
    };
  }
}

/** Google refuses a caller over its quota with a 403 that is not about access. */
function isRateLimited(response: HttpResponse): boolean {
  if (response.status === 429) return true;
  if (response.status !== 403) return false;
  const parsed = refusal.safeParse(jsonOf(response.body));
  return (
    parsed.success &&
    parsed.data.error.errors.some((error) => RATE_LIMIT_REASONS.has(error.reason ?? ''))
  );
}

/**
 * One Google instance as an occurrence, or null for one the household should
 * not see: cancelled, or declined by the account's owner.
 */
export function occurrenceFromGoogle(event: GoogleEvent): ExternalOccurrence | null {
  if (event.status === 'cancelled') return null;
  const self = event.attendees?.find((attendee) => attendee.self === true);
  if (self?.responseStatus === 'declined') return null;
  const time = googleTimeOf(event);
  if (time === null) return null;
  return { externalId: event.id, title: event.summary ?? '', time };
}

function googleTimeOf(event: GoogleEvent): OccurrenceTime | null {
  const { start, end } = event;
  if (start.date !== undefined && end.date !== undefined) {
    return { kind: 'allDay', startDate: start.date, endDateExclusive: end.date };
  }
  if (start.dateTime === undefined || end.dateTime === undefined) return null;
  const startAt = new Date(start.dateTime);
  const endAt = new Date(end.dateTime);
  if (Number.isNaN(startAt.getTime()) || Number.isNaN(endAt.getTime())) return null;
  return { kind: 'timed', start: startAt, end: endAt };
}
