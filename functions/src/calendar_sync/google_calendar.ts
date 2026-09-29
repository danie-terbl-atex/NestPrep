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
  HttpUnreachable,
  formBody,
  jsonOf,
} from '../shared/http_client';
import { addressOnIdToken, codeGrant, refreshGrant, requestTokens } from './oauth_tokens';
import type { OAuthClient } from './sync_config';

/**
 * Google Calendar, read-only, through its REST API (calendar ADR-0003). The
 * primary calendar only; repeating events are expanded by Google
 * (`singleEvents=true`), each instance with its own instant, computed in the
 * event's own zone — so a weekly 07:30 keeps its time across a clocks change.
 */
export const GOOGLE_AUTHORIZE_URL = 'https://accounts.google.com/o/oauth2/v2/auth';
export const GOOGLE_TOKEN_URL = 'https://oauth2.googleapis.com/token';
export const GOOGLE_REVOKE_URL = 'https://oauth2.googleapis.com/revoke';
export const GOOGLE_EVENTS_URL = 'https://www.googleapis.com/calendar/v3/calendars/primary/events';
export const GOOGLE_SCOPES = 'openid email https://www.googleapis.com/auth/calendar.readonly';

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

export type GoogleEvent = z.infer<typeof googleEvent>;

export class GoogleCalendar implements OAuthCalendar {
  constructor(
    private readonly client: OAuthClient,
    private readonly http: HttpClient,
  ) {}

  authorizationUrl(request: AuthorizationRequest): string {
    const query = new URLSearchParams({
      client_id: this.client.clientId,
      redirect_uri: request.redirectUri,
      response_type: 'code',
      scope: GOOGLE_SCOPES,
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

    const occurrences: ExternalOccurrence[] = [];
    let pageToken: string | undefined;
    for (let page = 0; page < MAX_PAGES; page++) {
      const result = await this.page(tokens.accessToken, window, pageToken);
      if (result.kind !== 'page') return result;
      occurrences.push(...result.occurrences);
      pageToken = result.next;
      if (pageToken === undefined) break;
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

  private async page(
    accessToken: string,
    window: SyncWindow,
    pageToken: string | undefined,
  ): Promise<
    | { kind: 'page'; occurrences: ExternalOccurrence[]; next: string | undefined }
    | { kind: 'revoked' }
    | { kind: 'unreachable' }
  > {
    const query = new URLSearchParams({
      singleEvents: 'true',
      orderBy: 'startTime',
      timeMin: window.timeMin.toISOString(),
      timeMax: window.timeMax.toISOString(),
      maxResults: String(PAGE_SIZE),
      ...(pageToken === undefined ? {} : { pageToken }),
    });
    let response;
    try {
      response = await this.http.send(`${GOOGLE_EVENTS_URL}?${query.toString()}`, {
        method: 'GET',
        headers: { Authorization: `Bearer ${accessToken}` },
      });
    } catch (error) {
      if (error instanceof HttpUnreachable) return { kind: 'unreachable' };
      throw error;
    }
    if (response.status === 401 || response.status === 403) return { kind: 'revoked' };
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
