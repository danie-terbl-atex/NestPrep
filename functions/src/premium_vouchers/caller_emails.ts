import type { Firestore, Transaction } from 'firebase-admin/firestore';

import { auth } from '../shared/auth';
import { emailHashOf, normEmail } from './premium_hashes';
import { verifiedEmailsDocument, verifiedEmailsRef } from './voucher_documents';

export interface UserDirectory {
  provenEmails(uid: string): Promise<readonly string[]>;
}

const PROVIDERS_THAT_PROVE_EMAIL = ['google.com', 'apple.com'];

export interface SignInRecord {
  readonly email?: string | undefined;
  readonly emailVerified: boolean;
  readonly providerData: readonly {
    readonly providerId: string;
    readonly email?: string | undefined;
  }[];
}

export function provenEmailsOf(user: SignInRecord): string[] {
  const raw = [
    ...(user.emailVerified && user.email !== undefined ? [user.email] : []),
    ...user.providerData
      .filter((provider) => PROVIDERS_THAT_PROVE_EMAIL.includes(provider.providerId))
      .flatMap((provider) => (provider.email === undefined ? [] : [provider.email])),
  ];
  return [...new Set(raw.flatMap((email) => normEmail(email) ?? []))];
}

export const liveUserDirectory: UserDirectory = {
  async provenEmails(uid) {
    return provenEmailsOf(await auth().getUser(uid));
  },
};

export async function verifiedEmailHashes(
  store: Firestore,
  uid: string,
  transaction?: Transaction,
): Promise<string[]> {
  const ref = verifiedEmailsRef(store, uid);
  const snapshot = await (transaction === undefined ? ref.get() : transaction.get(ref));
  const parsed = verifiedEmailsDocument.safeParse(snapshot.data() ?? {});
  return parsed.success ? Object.keys(parsed.data.emails) : [];
}

export async function callerEmailHashes(
  deps: { readonly store: Firestore; readonly users: UserDirectory; readonly pepper: string },
  uid: string,
  transaction?: Transaction,
): Promise<string[]> {
  const proven = await provenEmailHashes(deps, uid);
  const verified = await verifiedEmailHashes(deps.store, uid, transaction);
  return [...new Set([...proven, ...verified])];
}

export async function provenEmailHashes(
  deps: { readonly users: UserDirectory; readonly pepper: string },
  uid: string,
): Promise<string[]> {
  const emails = await deps.users.provenEmails(uid);
  return Promise.all(emails.map((email) => emailHashOf(deps.pepper, email)));
}
