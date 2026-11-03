import {
  WebStandardStreamableHTTPServerTransport,
  createMcpHandler,
  isLegacyRequest,
} from '@modelcontextprotocol/server';
import type { Firestore } from 'firebase-admin/firestore';
import { logger } from 'firebase-functions/v2';

import { db } from '../../shared/firestore';
import { ASSISTANT_SCOPES } from '../assistant_scopes';
import { requireSwitchedOn } from '../assistant_access';
import { AssistantRefusal, type AssistantPrincipal, type Authenticate } from '../principal';
import { assistantsIssuer, resourceMetadataOf, resourceOf } from '../auth/assistants_config';
import { buildMcpServer, type McpCallContext } from './mcp_server';
import { toolNamed } from './tools';

/**
 * The HTTP request as Cloud Functions hands it over: Express's, with the
 * body already parsed for JSON and the bytes kept in `rawBody`.
 */
export interface McpHttpRequest {
  readonly method: string;
  readonly headers: Readonly<Record<string, string | string[] | undefined>>;
  readonly body?: unknown;
  readonly rawBody?: Buffer;
}

/** The part of Express's response this handler writes through. */
export interface McpHttpResponse {
  status(code: number): unknown;
  setHeader(name: string, value: string): unknown;
  send(body: string): unknown;
  end(): unknown;
}

export interface McpHandlerOptions {
  readonly store?: () => Firestore;
  readonly now?: () => Date;
  readonly origin?: () => string;
}

/**
 * Browser origins besides our own an MCP call may come from: the two hosts'
 * web apps. A call from Claude's or ChatGPT's servers sends no `Origin`.
 */
export const ALLOWED_ORIGINS = ['https://claude.ai', 'https://claude.com', 'https://chatgpt.com'];

/** Request headers not passed on to the SDK: hop-by-hop, the credential, the cookie. */
const DROPPED_HEADERS = new Set([
  'authorization',
  'connection',
  'content-length',
  'cookie',
  'host',
  'transfer-encoding',
]);

interface Peek {
  readonly id: string | number | null;
  readonly method: string | null;
  readonly toolName: string | null;
}

function headerOf(req: McpHttpRequest, name: string): string | undefined {
  const value = req.headers[name];
  return Array.isArray(value) ? value[0] : value;
}

function bodyTextOf(req: McpHttpRequest): string {
  if (req.rawBody !== undefined) return req.rawBody.toString('utf8');
  if (typeof req.body === 'string') return req.body;
  if (req.body === undefined || req.body === null) return '';
  return JSON.stringify(req.body);
}

function parsedOrUndefined(text: string): unknown {
  if (text === '') return undefined;
  try {
    const value: unknown = JSON.parse(text);
    return value;
  } catch {
    return undefined;
  }
}

function fieldOf(value: unknown, key: string): unknown {
  return typeof value === 'object' && value !== null && !Array.isArray(value)
    ? (Object.entries(value).find(([name]) => name === key)?.[1] ?? undefined)
    : undefined;
}

/** What the message is, read only to choose an HTTP answer; the SDK parses it properly. */
function peek(parsed: unknown): Peek {
  const id = fieldOf(parsed, 'id');
  const method = fieldOf(parsed, 'method');
  const name = fieldOf(fieldOf(parsed, 'params'), 'name');
  return {
    id: typeof id === 'string' || typeof id === 'number' ? id : null,
    method: typeof method === 'string' ? method : null,
    toolName: method === 'tools/call' && typeof name === 'string' ? name : null,
  };
}

function jsonRpcError(
  status: number,
  id: string | number | null,
  code: number,
  message: string,
  headers: Record<string, string> = {},
): Response {
  return new Response(JSON.stringify({ jsonrpc: '2.0', id, error: { code, message } }), {
    status,
    headers: { 'Content-Type': 'application/json', ...headers },
  });
}

/** `WWW-Authenticate` for a missing or bad token, naming every scope (assistants ADR-0002). */
export function invalidTokenChallenge(origin: string, tokenSent: boolean): string {
  const error = tokenSent ? 'error="invalid_token", ' : '';
  return `Bearer ${error}resource_metadata="${resourceMetadataOf(origin)}", scope="${ASSISTANT_SCOPES.join(' ')}"`;
}

/** `WWW-Authenticate` for a scope this connection was not given, so the host can step up. */
export function insufficientScopeChallenge(origin: string, scope: string): string {
  return `Bearer error="insufficient_scope", scope="${scope}", resource_metadata="${resourceMetadataOf(origin)}"`;
}

/** The HTTP answer for a refusal that is not a tool result. */
function refusalResponse(
  refusal: AssistantRefusal,
  id: string | number | null,
  origin: string,
  tokenSent: boolean,
): Response {
  switch (refusal.kind) {
    case 'invalidToken':
      return jsonRpcError(401, id, -32000, 'Sign in to NestPrep again.', {
        'WWW-Authenticate': invalidTokenChallenge(origin, tokenSent),
      });
    case 'insufficientScope':
      return jsonRpcError(403, id, -32000, refusal.message, {
        'WWW-Authenticate': insufficientScopeChallenge(origin, refusal.scope ?? ''),
      });
    case 'switchedOff':
      return jsonRpcError(503, id, -32000, refusal.message);
    case 'rateLimited':
      return jsonRpcError(429, id, -32000, refusal.message);
    case 'forbidden':
    case 'notFound':
    case 'badRequest':
    case 'conflict':
      return jsonRpcError(403, id, -32000, refusal.message);
  }
}

function webRequestOf(req: McpHttpRequest, origin: string, body: string): Request {
  const headers: [string, string][] = Object.entries(req.headers).flatMap(([name, value]) => {
    if (DROPPED_HEADERS.has(name.toLowerCase()) || value === undefined) return [];
    return [[name, Array.isArray(value) ? value.join(', ') : value]];
  });
  return new Request(resourceOf(origin), { method: 'POST', headers, body });
}

async function serveLegacy(
  request: Request,
  parsed: unknown,
  context: McpCallContext,
): Promise<Response> {
  const server = buildMcpServer(context);
  const transport = new WebStandardStreamableHTTPServerTransport({
    sessionIdGenerator: undefined,
    enableJsonResponse: true,
  });
  await server.connect(transport);
  try {
    return await transport.handleRequest(
      request,
      parsed === undefined ? {} : { parsedBody: parsed },
    );
  } finally {
    await transport.close();
    await server.close();
  }
}

async function serveModern(request: Request, context: McpCallContext): Promise<Response> {
  const handler = createMcpHandler(() => buildMcpServer(context), {
    legacy: 'reject',
    responseMode: 'json',
  });
  try {
    return await handler.fetch(request);
  } finally {
    await handler.close();
  }
}

interface Dependencies {
  readonly authenticate: Authenticate;
  readonly store: () => Firestore;
  readonly now: () => Date;
  readonly origin: () => string;
}

/** One request, answered as a web `Response`. */
async function respond(req: McpHttpRequest, deps: Dependencies): Promise<Response> {
  const origin = deps.origin();
  const callerOrigin = headerOf(req, 'origin');
  if (
    callerOrigin !== undefined &&
    callerOrigin !== origin &&
    !ALLOWED_ORIGINS.includes(callerOrigin)
  ) {
    return jsonRpcError(403, null, -32000, 'Requests from this origin are not accepted.');
  }
  if (req.method.toUpperCase() !== 'POST') {
    return jsonRpcError(405, null, -32000, 'Method not allowed.', { Allow: 'POST' });
  }

  const text = bodyTextOf(req);
  const parsed = parsedOrUndefined(text);
  if (Array.isArray(parsed)) {
    return jsonRpcError(400, null, -32600, 'Batches are not supported.');
  }
  const message = peek(parsed);
  const authorization = headerOf(req, 'authorization');
  const tokenSent = authorization !== undefined && authorization.trim() !== '';
  const now = deps.now();
  const store = deps.store();

  let principal: AssistantPrincipal;
  try {
    principal = await deps.authenticate(authorization, now);
    await requireSwitchedOn(store);
  } catch (error) {
    if (!(error instanceof AssistantRefusal)) throw error;
    logger.info('assistant call refused', { kind: error.kind, reason: error.reason });
    return refusalResponse(error, message.id, origin, tokenSent);
  }

  if (message.method === 'subscriptions/listen') {
    return jsonRpcError(404, message.id, -32601, 'Method not found');
  }
  const tool = message.toolName === null ? undefined : toolNamed(message.toolName);
  if (tool !== undefined && !principal.scopes.includes(tool.scope)) {
    return refusalResponse(
      new AssistantRefusal(
        'insufficientScope',
        'scopeNotGranted',
        `This connection was not given ${tool.scope}.`,
        tool.scope,
      ),
      message.id,
      origin,
      tokenSent,
    );
  }

  const escalation: { refusal: AssistantRefusal | null } = { refusal: null };
  const context: McpCallContext = {
    store,
    principal,
    now,
    escalate: (refusal) => {
      escalation.refusal ??= refusal;
    },
  };
  const request = webRequestOf(req, origin, text);
  const legacy = await isLegacyRequest(request, parsed);
  const response = legacy
    ? await serveLegacy(request, parsed, context)
    : await serveModern(request, context);
  return escalation.refusal === null
    ? response
    : refusalResponse(escalation.refusal, message.id, origin, tokenSent);
}

async function send(res: McpHttpResponse, response: Response): Promise<void> {
  const body = await response.text();
  res.status(response.status);
  response.headers.forEach((value, name) => {
    if (name !== 'content-length') res.setHeader(name, value);
  });
  res.setHeader('Cache-Control', 'no-store');
  if (body === '') res.end();
  else res.send(body);
}

/**
 * The MCP endpoint (assistants ADR-0001, ADR-0003): Streamable HTTP,
 * stateless, JSON responses only, for 2026-07-28 clients and for 2025-11-25
 * and 2025-06-18 clients that still open with `initialize`. In order: the
 * `Origin` must be ours or a host's web app; only POST; never a JSON-RPC
 * batch, which 2025-06-18 removed and which would otherwise run many calls
 * on one authentication and one rate-limit charge (-32600); the bearer token
 * becomes a principal (401 with the RFC 9728 challenge otherwise); both off
 * switches are read (503); a tool's scope must have been granted (403
 * `insufficient_scope`, so the host can ask for more). Every answer is
 * `Cache-Control: no-store`, because Hosting's CDN caches what it may.
 *
 * `assistantMcp` serves it with `authenticateBearer`; tests inject their own
 * `Authenticate`.
 */
export function mcpHandler(
  authenticate: Authenticate,
  options: McpHandlerOptions = {},
): (req: McpHttpRequest, res: McpHttpResponse) => Promise<void> {
  const deps: Dependencies = {
    authenticate,
    store: options.store ?? db,
    now: options.now ?? ((): Date => new Date()),
    origin: options.origin ?? assistantsIssuer,
  };
  return async (req, res) => {
    let response: Response;
    try {
      response = await respond(req, deps);
    } catch (error) {
      logger.error('assistant call failed', {
        failure: error instanceof Error ? error.name : 'unknown',
      });
      response = jsonRpcError(500, null, -32603, 'Internal error');
    }
    await send(res, response);
  };
}
