import { getApps, initializeApp } from 'firebase-admin/app';
import { getFirestore, type Firestore } from 'firebase-admin/firestore';

/**
 * The one admin Firestore handle every Function shares. Initialised lazily so
 * importing a module never starts the SDK — the emulator and the unit tests
 * both import these files without one.
 */
export function db(): Firestore {
  if (getApps().length === 0) {
    initializeApp();
  }
  return getFirestore();
}
