import { z } from 'zod';

import type {
  AuthorizationRequest,
  CodeExchange,
  ExchangedAccount,
  FetchOutcome,
  OAuthCalendar,
} from './calendar_source';
import type { ExternalOccurrence, OccurrenceTime, SyncWindow } from './external_occurrence';
import { type HttpClient, HttpUnreachable, jsonOf } from '../shared/http_client';
import {
  type TokenEndpoint,
  addressOnIdToken,
  codeGrant,
  refreshGrant,
  requestTokens,
} from './oauth_tokens';
import type { OAuthClient } from './sync_config';

/**
 * Outlook — Microsoft 365 work and school accounts and Outlook.com — through
 * Microsoft Graph, read-only (calendar ADR-0003). `calendarView` expands
 * repeating events into instances, each asked for in UTC, so the Function only
 * ever converts an instant to the household's clock.
 */
export const MICROSOFT_AUTHORIZE_URL =
  'https://login.microsoftonline.com/common/oauth2/v2.0/authorize';
export const MICROSOFT_TOKEN_URL = 'https://login.microsoftonline.com/common/oauth2/v2.0/token';
export const MICROSOFT_CALENDAR_VIEW_URL = 'https://graph.microsoft.com/v1.0/me/calendarView';
export const MICROSOFT_SCOPES = 'openid email offline_access User.Read Calendars.Read';

const PAGE_SIZE = 250;
const MAX_PAGES = 4;

const graphTime = z.object({ dateTime: z.string() });

const graphEvent = z.object({
  id: z.string(),
  subject: z.string().nullable().optional(),
  isAllDay: z.boolean().optional(),
  isCancelled: z.boolean().optional(),
  start: graphTime,
  end: graphTime,
  responseStatus: z.object({ response: z.string().optional() }).nullable().optional(),
});

const viewPage = z.object({
  value: z.array(z.unknown()).default([]),
  '@odata.nextLink': z.string().optional(),
});

export type GraphEvent = z.infer<typeof graphEvent>;

export class MicrosoftCalendar implements OAuthCalendar {
  constructor(
    private readonly client: OAuthClient,
    private readonly http: HttpClient,
  ) {}

  private get tokenEndpoint(): TokenEndpoint {
    return { url: MICROSOFT_TOKEN_URL, client: this.client, extra: { scope: MICROSOFT_SCOPES } };
  }

  authorizationUrl(request: AuthorizationRequest): string {
    const query = new URLSearchParams({
      client_id: this.client.clientId,
      redirect_uri: request.redirectUri,
      response_type: 'code',
      response_mode: 'query',
      scope: MICROSOFT_SCOPES,
      prompt: 'select_account',
      state: request.state,
      code_challenge: request.codeChallenge,
      code_challenge_method: 'S256',
    });
    return `${MICROSOFT_AUTHORIZE_URL}?${query.toString()}`;
  }

  async exchangeCode(exchange: CodeExchange): Promise<ExchangedAccount | null> {
    const tokens = await requestTokens(
      this.http,
      this.tokenEndpoint,
      codeGrant(exchange.code, exchange.codeVerifier, exchange.redirectUri),
    );
    if (tokens.kind !== 'ok' || tokens.refreshToken === null) return null;
    return { refreshToken: tokens.refreshToken, accountLabel: addressOnIdToken(tokens.idToken) };
  }

  async fetchOccurrences(credential: string, window: SyncWindow): Promise<FetchOutcome> {
    const tokens = await requestTokens(this.http, this.tokenEndpoint, refreshGrant(credential));
    if (tokens.kind !== 'ok') return tokens;

    const query = new URLSearchParams({
      startDateTime: window.timeMin.toISOString(),
      endDateTime: window.timeMax.toISOString(),
      $top: String(PAGE_SIZE),
      $select: 'id,subject,isAllDay,isCancelled,start,end,responseStatus',
    });
    let url: string | undefined = `${MICROSOFT_CALENDAR_VIEW_URL}?${query.toString()}`;
    const occurrences: ExternalOccurrence[] = [];
    for (let page = 0; page < MAX_PAGES && url !== undefined; page++) {
      const result = await this.page(tokens.accessToken, url);
      if (result.kind !== 'page') return result;
      occurrences.push(...result.occurrences);
      url = result.next;
    }
    // Microsoft rotates refresh tokens on every use; the old one keeps working
    // for a while, but the newest is the one to keep.
    return { kind: 'ok', occurrences, refreshedCredential: tokens.refreshToken };
  }

  /**
   * Graph has no per-app token revocation short of signing the person out of
   * every session; the member removes NestPrep from their account's apps.
   * Deleting the stored token is what disconnecting does here (ADR-0003).
   */
  revoke(): Promise<void> {
    return Promise.resolve();
  }

  private async page(
    accessToken: string,
    url: string,
  ): Promise<
    | { kind: 'page'; occurrences: ExternalOccurrence[]; next: string | undefined }
    | { kind: 'revoked' }
    | { kind: 'unreachable' }
  > {
    let response;
    try {
      response = await this.http.send(url, {
        method: 'GET',
        headers: { Authorization: `Bearer ${accessToken}`, Prefer: 'outlook.timezone="UTC"' },
      });
    } catch (error) {
      if (error instanceof HttpUnreachable) return { kind: 'unreachable' };
      throw error;
    }
    if (response.status === 401 || response.status === 403) return { kind: 'revoked' };
    if (response.status !== 200) return { kind: 'unreachable' };
    const parsed = viewPage.safeParse(jsonOf(response.body));
    if (!parsed.success) return { kind: 'unreachable' };
    return {
      kind: 'page',
      occurrences: parsed.data.value.flatMap((item) => {
        const event = graphEvent.safeParse(item);
        if (!event.success) return [];
        const occurrence = occurrenceFromGraph(event.data);
        return occurrence === null ? [] : [occurrence];
      }),
      next: onGraph(parsed.data['@odata.nextLink']),
    };
  }
}

/**
 * The next page, only while it is still Graph: the access token rides on the
 * request, and a link somewhere else is not somewhere it should go.
 */
function onGraph(link: string | undefined): string | undefined {
  return link?.startsWith('https://graph.microsoft.com/') === true ? link : undefined;
}

/** One Graph instance as an occurrence; null when cancelled or declined. */
export function occurrenceFromGraph(event: GraphEvent): ExternalOccurrence | null {
  if (event.isCancelled === true) return null;
  if (event.responseStatus?.response === 'declined') return null;
  const time = graphTimeOf(event);
  if (time === null) return null;
  return { externalId: event.id, title: event.subject ?? '', time };
}

function graphTimeOf(event: GraphEvent): OccurrenceTime | null {
  if (event.isAllDay === true) {
    // An all-day event is midnight to midnight on the day it is written for;
    // its date is the date, whatever zone the header asked for.
    return {
      kind: 'allDay',
      startDate: event.start.dateTime.slice(0, 10),
      endDateExclusive: event.end.dateTime.slice(0, 10),
    };
  }
  const start = utcInstant(event.start.dateTime);
  const end = utcInstant(event.end.dateTime);
  if (start === null || end === null) return null;
  return { kind: 'timed', start, end };
}

/** Graph writes `2026-10-06T15:00:00.0000000` with the zone in a header. */
function utcInstant(dateTime: string): Date | null {
  const instant = new Date(`${dateTime.slice(0, 19)}Z`);
  return Number.isNaN(instant.getTime()) ? null : instant;
}
