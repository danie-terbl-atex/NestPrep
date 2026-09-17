import { HttpsError } from 'firebase-functions/v2/https';

export interface PingRequest {
  readonly sentFrom: string;
}

export interface PongResponse {
  readonly echo: string;
  readonly receivedAt: string;
}

// Input is parsed at the edge, never cast (ENG-09, BE-03).
export function parsePingRequest(data: unknown): PingRequest {
  if (typeof data !== 'object' || data === null) {
    throw new HttpsError('invalid-argument', 'A ping needs a body.');
  }
  const sentFrom = (data as Record<string, unknown>)['sentFrom'];
  if (typeof sentFrom !== 'string' || sentFrom.length === 0) {
    throw new HttpsError('invalid-argument', 'A ping says where it came from.');
  }
  return { sentFrom };
}

export function pong(request: PingRequest, now: Date = new Date()): PongResponse {
  return { echo: request.sentFrom, receivedAt: now.toISOString() };
}
