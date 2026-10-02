/**
 * The one region every callable runs in, chosen 2026-09-18 to match the
 * Firestore database (foundation ADR-0003).
 *
 * This is a **contract with the Flutter client**, not a server detail. A
 * callable is addressed by region: the SDK's default is `us-central1`, so a
 * client that does not name this one calls a URL where nothing is deployed and
 * gets NOT_FOUND on every household action. The Dart half is
 * `app/lib/app/firebase_bootstrap.dart`, and
 * `test/unit/region_contract.test.ts` reads both files and fails if they drift
 * (the vault's lesson on contracts between two languages).
 *
 * It cannot be changed by editing this line alone: a deployed function's region
 * is fixed, so moving it means deploying to the new region and deleting the old
 * functions, with a window where the client can reach neither.
 */
export const FUNCTIONS_REGION = 'africa-south1';

/**
 * Where scheduled functions run (foundation ADR-0017). Cloud Scheduler has no
 * `africa-south1` location, so an `onSchedule` function deployed there gets
 * its function but never its job, and never fires. Scheduled work is batch
 * work that no client addresses, so it runs in the nearest Scheduler region
 * and reads and writes the `africa-south1` database from there.
 */
export const SCHEDULER_REGION = 'europe-west1';

/**
 * Where an HTTP function the public site rewrites to runs. Firebase Hosting
 * cannot rewrite to `africa-south1`, so the one such function — the account
 * deletion form — runs here and reads and writes the `africa-south1` database.
 */
export const HOSTING_REGION = 'europe-west1';
