import type { CallableOptions } from 'firebase-functions/v2/https';

/**
 * The two account-data callables do more than one person's ordinary request:
 * erasing walks every household the account is in and may end one with all
 * its documents and bytes; an export reads all of it. They take more time and
 * memory than the callables' thirty seconds and 256 MiB, and still a bounded
 * amount (`BE-19`); everything else is the global options'.
 */
export const ERASURE_OPTIONS: CallableOptions = { timeoutSeconds: 300, memory: '512MiB' };
export const EXPORT_OPTIONS: CallableOptions = { timeoutSeconds: 120, memory: '512MiB' };
