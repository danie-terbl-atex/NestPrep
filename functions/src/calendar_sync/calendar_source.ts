import type { ExternalOccurrence, SyncWindow } from './external_occurrence';

/**
 * How one read of a calendar went. Every way it can fail is a state the
 * connection is left in and a sentence on the screen — never an exception that
 * reaches a person (FE-09, BE-04).
 */
export type FetchOutcome =
  | {
      readonly kind: 'ok';
      readonly occurrences: readonly ExternalOccurrence[];
      /** A provider that rotates refresh tokens hands back the next one here. */
      readonly refreshedCredential: string | null;
    }
  | { readonly kind: 'revoked' }
  | { readonly kind: 'unreachable' }
  | { readonly kind: 'notACalendar' }
  | { readonly kind: 'notConfigured' };

/** A calendar NestPrep can read from (BE-09: one adapter per third party). */
export interface CalendarSource {
  fetchOccurrences(credential: string, window: SyncWindow): Promise<FetchOutcome>;

  /**
   * Tells the provider NestPrep no longer holds the credential. Best effort: a
   * provider that is down does not stop a disconnect (BE-09).
   */
  revoke(credential: string): Promise<void>;
}

export interface AuthorizationRequest {
  readonly state: string;
  readonly codeChallenge: string;
  readonly redirectUri: string;
}

export interface CodeExchange {
  readonly code: string;
  readonly codeVerifier: string;
  readonly redirectUri: string;
}

export interface ExchangedAccount {
  readonly refreshToken: string;
  /** The account's address, for "Sam's Google — sam@example.com". */
  readonly accountLabel: string;
}

/** A provider a member connects through OAuth 2.0 with PKCE. */
export interface OAuthConnector {
  authorizationUrl(request: AuthorizationRequest): string;

  /** Null when the provider would not give a refresh token for the code. */
  exchangeCode(exchange: CodeExchange): Promise<ExchangedAccount | null>;
}

export type OAuthCalendar = CalendarSource & OAuthConnector;
