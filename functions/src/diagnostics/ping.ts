import { onCall } from 'firebase-functions/v2/https';

import { parsePingRequest, pong } from './pong';

// Foundation smoke test: proves a callable round-trips through the emulator.
// Removed with the diagnostics feature in accounts phase 1.
export const ping = onCall((request) => pong(parsePingRequest(request.data)));
