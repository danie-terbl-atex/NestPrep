import { setGlobalOptions } from 'firebase-functions/v2';

export { ping } from './diagnostics/ping';

// One region for every function, chosen when the cloud project exists
// (foundation ADR-0003). Explicit limits are BE-19.
setGlobalOptions({ maxInstances: 10, timeoutSeconds: 30, memory: '256MiB' });
