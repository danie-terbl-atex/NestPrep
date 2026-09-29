/**
 * Reads a configuration value, treating empty and the deploy placeholder as
 * absent (BE-16). A bound Secret Manager secret must exist to deploy, so a
 * project that has not set one up holds the value `unset`, which has to read
 * as "not configured" rather than as a credential. Calendar sync and
 * subscriptions both read their parameters through this (`ENG-02`).
 */
export function configured(value: string): string | null {
  const trimmed = value.trim();
  return trimmed === '' || trimmed === 'unset' ? null : trimmed;
}
