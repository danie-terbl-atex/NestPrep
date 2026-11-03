import type { Firestore } from 'firebase-admin/firestore';

import type { UserDirectory } from './caller_emails';

export interface VoucherDeps {
  readonly store: Firestore;
  readonly users: UserDirectory;
  readonly pepper: string;
  readonly testers: readonly string[];
  readonly now: Date;
}
