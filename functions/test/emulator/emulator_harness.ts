import { deleteApp, getApps, initializeApp } from 'firebase-admin/app';
import { getFirestore, type Firestore } from 'firebase-admin/firestore';

/**
 * Drives the callables the way the app does — over HTTP, with a real ID token
 * from the Auth emulator — so a test proves the wiring and the authorisation,
 * not just the function body (BE-14).
 */
export const PROJECT_ID = 'nestprep-643b7';
export const REGION = 'us-central1';

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

export async function signUp(): Promise<TestUser> {
  nextUser += 1;
  const email = `test-${Date.now().toString()}-${nextUser.toString()}@nestprep.test`;
  const response = await fetch(
    `http://${AUTH_HOST}/identitytoolkit.googleapis.com/v1/accounts:signUp?key=fake-api-key`,
    {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ email, password: 'nestprep', returnSecureToken: true }),
    },
  );
  const body = (await response.json()) as { idToken?: string; localId?: string };
  if (body.idToken === undefined || body.localId === undefined) {
    throw new Error(`could not seed a test user: ${JSON.stringify(body)}`);
  }
  return { uid: body.localId, idToken: body.idToken, email };
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

export function adminDb(): Firestore {
  if (store === undefined) {
    process.env['FIRESTORE_EMULATOR_HOST'] = FIRESTORE_HOST;
    const app =
      getApps().find((candidate) => candidate.name === 'tests') ??
      initializeApp({ projectId: PROJECT_ID }, 'tests');
    store = getFirestore(app);
  }
  return store;
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
