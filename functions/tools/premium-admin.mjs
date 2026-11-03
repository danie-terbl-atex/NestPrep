import { initializeApp } from 'firebase-admin/app';
import { getFirestore } from 'firebase-admin/firestore';

export const REAL_PROJECT = 'nestprep-643b7';

export const PROJECT_OPTIONS = {
  project: { type: 'string' },
  yes: { type: 'boolean', default: false },
};

export function refuse(message) {
  console.error(message);
  process.exit(2);
}

export async function premiumAdmin(values) {
  const real = values.project !== undefined;
  if (real && (values.project !== REAL_PROJECT || !values.yes)) {
    refuse(`the real project needs exactly --project ${REAL_PROJECT} --yes`);
  }
  if (real && process.env.FIRESTORE_EMULATOR_HOST !== undefined) {
    refuse('FIRESTORE_EMULATOR_HOST is set: unset it for the real project, or drop --project');
  }
  if (!real) process.env.FIRESTORE_EMULATOR_HOST ??= '127.0.0.1:8080';
  process.env.GCLOUD_PROJECT ??= REAL_PROJECT;

  const { EMULATOR_PEPPER } = await import('../lib/premium_vouchers/premium_config.js');
  const pepper = real ? (process.env.PREMIUM_EMAIL_PEPPER ?? '').trim() : EMULATOR_PEPPER;
  if (pepper === '' || pepper === 'unset') refuse('PREMIUM_EMAIL_PEPPER is not set');

  return {
    store: getFirestore(initializeApp({ projectId: REAL_PROJECT })),
    pepper,
    target: real
      ? `project ${REAL_PROJECT}`
      : `the emulator at ${process.env.FIRESTORE_EMULATOR_HOST}`,
  };
}
