export interface WoolworthsSessionLink {
  readonly sealed: string;
  readonly idExpiresAt: Date;
  readonly linkedAt: Date;
  readonly emailMasked: string | null;
}

export interface WoolworthsLink {
  readonly session: WoolworthsSessionLink | null;
}

export type SessionSwap = 'replaced' | 'changed' | 'gone';

export interface WoolworthsLinkStore {
  read(uid: string): Promise<WoolworthsLink | null>;
  saveSession(uid: string, session: WoolworthsSessionLink): Promise<void>;
  replaceSession(
    uid: string,
    expectedSealed: string,
    next: WoolworthsSessionLink,
  ): Promise<SessionSwap>;
  remove(uid: string): Promise<void>;
}
