import { getApps, initializeApp, type App } from 'firebase-admin/app';

/**
 * The one admin app every Function shares. Initialised lazily so importing a
 * module never starts the SDK — the emulator and the unit tests both import
 * these files without one.
 */
export function adminApp(): App {
  const [existing] = getApps();
  return existing ?? initializeApp();
}
