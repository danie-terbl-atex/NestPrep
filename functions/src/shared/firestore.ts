import { getFirestore, type Firestore } from 'firebase-admin/firestore';

import { adminApp } from './admin_app';

/** The one admin Firestore handle every Function shares. */
export function db(): Firestore {
  return getFirestore(adminApp());
}
