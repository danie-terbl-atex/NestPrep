import { FUNCTIONS_REGION } from './region';

/**
 * Where a Function of this codebase answers over HTTP: [base] when one is
 * configured, or the address Cloud Functions gives it, or the emulator's.
 *
 * Shared by calendar sync's feed and OAuth callback and by documents' share
 * links (`ENG-02`): each feature keeps its own base-URL parameter, because a
 * custom domain for one is not a custom domain for the other.
 */
export function functionUrlFrom(base: string | null, name: string): string {
  if (base !== null) return `${base.replace(/\/+$/, '')}/${name}`;
  const project = process.env['GCLOUD_PROJECT'] ?? '';
  if (process.env['FUNCTIONS_EMULATOR'] === 'true') {
    const host = process.env['FUNCTIONS_EMULATOR_HOST'] ?? '127.0.0.1:5001';
    return `http://${host}/${project}/${FUNCTIONS_REGION}/${name}`;
  }
  return `https://${FUNCTIONS_REGION}-${project}.cloudfunctions.net/${name}`;
}
