import { getAuth, type Auth } from 'firebase-admin/auth';

import { adminApp } from './admin_app';

/**
 * The one admin Auth handle. It exists for exactly one job: writing the
 * `households` custom claim that Storage Security Rules read, because they
 * cannot read Firestore (documents ADR-0001).
 */
export function auth(): Auth {
  return getAuth(adminApp());
}
