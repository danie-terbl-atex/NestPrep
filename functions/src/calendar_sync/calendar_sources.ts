import type { CalendarSource, OAuthCalendar } from './calendar_source';
import { GoogleCalendar } from './google_calendar';
import { type HttpClient, fetchHttpClient } from './http_client';
import { IcsCalendar } from './ics_calendar';
import { dnsResolver } from './link_guard';
import { MicrosoftCalendar } from './microsoft_calendar';
import { type OAuthClients, oauthClients } from './sync_config';
import type { OAuthProvider, Provider } from './sync_documents';

/**
 * Every calendar NestPrep can read, as this instance is configured. A provider
 * with no OAuth client is simply absent — the callers turn that into **not set
 * up yet**, never into an error (calendar ADR-0003).
 */
export interface CalendarSources {
  readonly ics: IcsCalendar;
  oauth(provider: OAuthProvider): OAuthCalendar | null;
  source(provider: Provider): CalendarSource | null;
}

export function calendarSourcesFor(
  clients: OAuthClients,
  http: HttpClient,
  ics: IcsCalendar,
): CalendarSources {
  const google = clients.google;
  const microsoft = clients.microsoft;
  const oauth = (provider: OAuthProvider): OAuthCalendar | null => {
    if (provider === 'google')
      return google === undefined ? null : new GoogleCalendar(google, http);
    return microsoft === undefined ? null : new MicrosoftCalendar(microsoft, http);
  };
  return {
    ics,
    oauth,
    source: (provider) => (provider === 'ics' ? ics : oauth(provider)),
  };
}

/**
 * The live sources. [withSecrets] is whether the calling Function is bound to
 * the client secrets; one that is not can still build authorization links.
 */
export function liveCalendarSources(withSecrets: boolean): CalendarSources {
  const isEmulator = process.env['FUNCTIONS_EMULATOR'] === 'true';
  return calendarSourcesFor(
    oauthClients(withSecrets),
    fetchHttpClient,
    new IcsCalendar(fetchHttpClient, dnsResolver, isEmulator),
  );
}
