import type { Response } from 'express';
import { logger } from 'firebase-functions/v2';
import { onRequest, type HttpsFunction, type Request } from 'firebase-functions/v2/https';
import type { z } from 'zod';

import { functionUrlFrom } from '../shared/function_url';
import { UnusableEmail } from './issue_vouchers';
import { premiumEmailPepper, storeInvokerEmail } from './premium_config';
import { type IdTokenCheck, googleIdTokenCheck, isStoreCaller } from './store_caller';

export interface StoreRequest {
  readonly method: string;
  readonly headers: Readonly<Record<string, string | string[] | undefined>>;
  readonly body: unknown;
}

export interface StoreReply {
  readonly status: number;
  readonly body: Readonly<Record<string, unknown>>;
}

export interface StoreCallDeps {
  readonly check: IdTokenCheck;
  readonly audience: string;
  readonly invokerEmail: string | null;
}

export async function answerStoreCall<S extends z.ZodType>(
  deps: StoreCallDeps,
  request: StoreRequest,
  schema: S,
  answer: (input: z.infer<S>) => Promise<Readonly<Record<string, unknown>>>,
): Promise<StoreReply> {
  if (request.method !== 'POST') return { status: 405, body: { error: 'badRequest' } };
  if (deps.invokerEmail === null) logger.error('STORE_INVOKER_SERVICE_ACCOUNT is not configured');
  const allowed = await isStoreCaller(
    deps.check,
    request.headers['authorization'],
    deps.audience,
    deps.invokerEmail,
  );
  if (!allowed) return { status: 403, body: { error: 'forbidden' } };
  const parsed = schema.safeParse(request.body);
  if (!parsed.success) return { status: 400, body: { error: 'badRequest' } };
  try {
    return { status: 200, body: await answer(parsed.data) };
  } catch (error) {
    if (error instanceof UnusableEmail) return { status: 400, body: { error: 'badRequest' } };
    throw error;
  }
}

export function storeEndpoint<S extends z.ZodType>(
  name: string,
  schema: S,
  answer: (input: z.infer<S>) => Promise<Readonly<Record<string, unknown>>>,
): HttpsFunction {
  return onRequest(
    { invoker: 'private', secrets: [premiumEmailPepper] },
    async (req: Request, res: Response) => {
      res.setHeader('Cache-Control', 'no-store');
      try {
        const reply = await answerStoreCall(
          {
            check: googleIdTokenCheck,
            audience: functionUrlFrom(null, name),
            invokerEmail: storeInvokerEmail(),
          },
          req,
          schema,
          answer,
        );
        res.status(reply.status).json(reply.body);
      } catch (error) {
        logger.error('premium store call failed', {
          endpoint: name,
          error: error instanceof Error ? error.message : String(error),
        });
        res.status(500).json({ error: 'unavailable' });
      }
    },
  );
}
