import { getAuth, type Auth } from 'firebase-admin/auth';

import { adminApp } from './admin_app';

/**
 * The one admin Auth handle. It exists for two jobs: writing the `households`
 * custom claim that Storage Security Rules read, because they cannot read
 * Firestore (documents ADR-0001), and opening and closing kid devices' users
 * and their custom tokens (accounts ADR-0003).
 */
export function auth(): Auth {
  return getAuth(adminApp());
}
