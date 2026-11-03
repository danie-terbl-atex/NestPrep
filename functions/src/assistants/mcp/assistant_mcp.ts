import { onRequest } from 'firebase-functions/v2/https';

import { HOSTING_REGION } from '../../shared/region';
import { authenticateBearer } from '../auth/bearer';
import { mcpHandler } from './mcp_handler';

/**
 * The MCP endpoint assistants call (assistants ADR-0001, ADR-0002), behind
 * Hosting's `/mcp` rewrite in the rewrite region, as `assistantAuth` is.
 * Public at the network: every call proves itself with a bearer token this
 * server's own authorization server issued, and the handler answers anything
 * else with the RFC 9728 challenge. Server-to-server, so there is no App Check.
 */
export const assistantMcp = onRequest(
  { region: HOSTING_REGION, invoker: 'public' },
  mcpHandler(authenticateBearer),
);
