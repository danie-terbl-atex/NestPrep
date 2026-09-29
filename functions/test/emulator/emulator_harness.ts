import { deleteApp, getApps, initializeApp, type App } from 'firebase-admin/app';
import { getAuth, type Auth } from 'firebase-admin/auth';
import { getFirestore, type Firestore } from 'firebase-admin/firestore';
import { FUNCTIONS_REGION } from '../../src/shared/region';

/**
 * Drives the callables the way the app does — over HTTP, with a real ID token
 * from the Auth emulator — so a test proves the wiring and the authorisation,
 * not just the function body (BE-14).
 */
export const PROJECT_ID = 'nestprep-643b7';
export const REGION = FUNCTIONS_REGION;

const AUTH_HOST = process.env['FIREBASE_AUTH_EMULATOR_HOST'] ?? '127.0.0.1:9099';
const FIRESTORE_HOST = process.env['FIRESTORE_EMULATOR_HOST'] ?? '127.0.0.1:8080';
const FUNCTIONS_HOST = process.env['FUNCTIONS_EMULATOR_HOST'] ?? '127.0.0.1:5001';

export interface TestUser {
  readonly uid: string;
  readonly idToken: string;
  readonly email: string;
}

/** A refusal as the client sees it: the gRPC status and our own reason. */
export class CallFailed extends Error {
  constructor(
    readonly status: string,
    readonly reason: string | undefined,
  ) {
    super(`${status}${reason === undefined ? '' : ` (${reason})`}`);
    this.name = 'CallFailed';
  }
}

let nextUser = 0;

const IDENTITY = `http://${AUTH_HOST}/identitytoolkit.googleapis.com/v1`;
const PASSWORD = 'nestprep';

/**
 * A signed-up user whose address is **verified**, which is what almost every
 * test wants: createHousehold and redeemInvite refuse an unverified caller
 * (accounts ADR-0002), and a Google credential — how people really arrive —
 * always carries the claim. Use `signUpUnverified` for the gate's own tests.
 */
export async function signUp(): Promise<TestUser> {
  const user = await signUpUnverified();
  await markVerified(user.uid);
  // The claim lives in the token, so a token minted before the flag was set
  // still says false. Signing in again is what picks it up.
  return { ...user, idToken: await signInAgain(user.email) };
}

/** A user who has not proved their address — the state the gate exists for. */
export async function signUpUnverified(): Promise<TestUser> {
  nextUser += 1;
  const email = `test-${Date.now().toString()}-${nextUser.toString()}@nestprep.test`;
  const response = await fetch(`${IDENTITY}/accounts:signUp?key=fake-api-key`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ email, password: PASSWORD, returnSecureToken: true }),
  });
  const body = (await response.json()) as { idToken?: string; localId?: string };
  if (body.idToken === undefined || body.localId === undefined) {
    throw new Error(`could not seed a test user: ${JSON.stringify(body)}`);
  }
  return { uid: body.localId, idToken: body.idToken, email };
}

/** Sets the flag the way the emulator's admin API allows, with no inbox involved. */
async function markVerified(uid: string): Promise<void> {
  const response = await fetch(`${IDENTITY}/accounts:update`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json', Authorization: 'Bearer owner' },
    body: JSON.stringify({ localId: uid, emailVerified: true, targetProjectId: PROJECT_ID }),
  });
  if (!response.ok) {
    throw new Error(`could not verify a test user: ${await response.text()}`);
  }
}

async function signInAgain(email: string): Promise<string> {
  const response = await fetch(`${IDENTITY}/accounts:signInWithPassword?key=fake-api-key`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ email, password: PASSWORD, returnSecureToken: true }),
  });
  const body = (await response.json()) as { idToken?: string };
  if (body.idToken === undefined) {
    throw new Error(`could not re-sign a test user: ${JSON.stringify(body)}`);
  }
  return body.idToken;
}

/**
 * What a kid device does with the token `redeemKidPairing` hands it: signs in
 * with it, exactly as the app's `signInWithCustomToken` does, and gets back the
 * ID token every later call carries (accounts ADR-0003).
 */
export async function signInWithCustomToken(token: string): Promise<TestUser> {
  const response = await fetch(`${IDENTITY}/accounts:signInWithCustomToken?key=fake-api-key`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ token, returnSecureToken: true }),
  });
  const body = (await response.json()) as { idToken?: string };
  if (body.idToken === undefined) {
    throw new Error(`could not sign in with a custom token: ${JSON.stringify(body)}`);
  }
  const claims = claimsOf(body.idToken);
  const uid = claims['user_id'];
  if (typeof uid !== 'string') throw new Error('the ID token named nobody');
  return { uid, idToken: body.idToken, email: '' };
}

/** The claims an ID token carries — what the rules and the callables see. */
export function claimsOf(idToken: string): Record<string, unknown> {
  const payload = idToken.split('.')[1] ?? '';
  return JSON.parse(Buffer.from(payload, 'base64url').toString('utf8')) as Record<string, unknown>;
}

export async function callAs<T>(user: TestUser | null, name: string, data: unknown): Promise<T> {
  const response = await fetch(`http://${FUNCTIONS_HOST}/${PROJECT_ID}/${REGION}/${name}`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      ...(user === null ? {} : { Authorization: `Bearer ${user.idToken}` }),
    },
    body: JSON.stringify({ data }),
  });
  const body = (await response.json()) as {
    result?: T;
    error?: { status?: string; details?: { reason?: string } };
  };
  if (body.error !== undefined) {
    throw new CallFailed(body.error.status ?? 'UNKNOWN', body.error.details?.reason);
  }
  return body.result as T;
}

let store: Firestore | undefined;

/** The admin app the tests read and write through, pointed at the emulators. */
function testApp(): App {
  process.env['FIRESTORE_EMULATOR_HOST'] = FIRESTORE_HOST;
  process.env['FIREBASE_AUTH_EMULATOR_HOST'] = AUTH_HOST;
  return (
    getApps().find((candidate) => candidate.name === 'tests') ??
    initializeApp({ projectId: PROJECT_ID }, 'tests')
  );
}

export function adminDb(): Firestore {
  store ??= getFirestore(testApp());
  return store;
}

/**
 * Auth as the server sees it. One test needs it: the custom claim
 * `syncDocumentAccess` writes is on the token, not in Firestore, so there is
 * nowhere else to read it back from (documents ADR-0001).
 */
export function adminAuth(): Auth {
  return getAuth(testApp());
}

export async function clearFirestore(): Promise<void> {
  await fetch(
    `http://${FIRESTORE_HOST}/emulator/v1/projects/${PROJECT_ID}/databases/(default)/documents`,
    { method: 'DELETE' },
  );
}

export async function closeAdmin(): Promise<void> {
  const app = getApps().find((candidate) => candidate.name === 'tests');
  if (app !== undefined) await deleteApp(app);
  store = undefined;
}

export type { Firestore };
