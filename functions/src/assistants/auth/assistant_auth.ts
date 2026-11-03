import type { Response } from 'express';
import { logger } from 'firebase-functions/v2';
import { onRequest, type Request } from 'firebase-functions/v2/https';

import { callerAddress } from '../../shared/client_address';
import { db } from '../../shared/firestore';
import { HOSTING_REGION } from '../../shared/region';
import {
  assistantsTokenKey,
  assistantsTokenKeyHere,
  authorizationServer,
  clientDocumentsMayBeLocal,
} from './assistants_config';
import { AUTH_REQUEST_LIFETIME_MS } from './auth_documents';
import { type AuthReply, authorizeErrorPage, json, sessionCookie, sessionFrom } from './auth_reply';
import { authorize } from './authorize';
import { clientDocumentFetch } from './client_document_fetch';
import { answerConsent } from './consent';
import { authorizationServerMetadata, protectedResourceMetadata } from './discovery';
import { adminIdTokenVerifier } from './fresh_sign_in';
import { registerClient } from './register_client';
import { revokeToken } from './revoke_token';
import { exchangeToken } from './token_endpoint';

/**
 * NestPrep's OAuth 2.1 authorization server for assistants (assistants
 * ADR-0002), one HTTPS function behind Hosting's rewrites of `/oauth/**` and
 * the two well-known paths. This file is only the transport: it routes,
 * hands each endpoint what it needs, and writes the reply — with
 * `Cache-Control: no-store` on every one, because Hosting's CDN caches
 * whatever does not say otherwise. Server-to-server, so there is no App Check.
 */
export const assistantAuth = onRequest(
  { region: HOSTING_REGION, invoker: 'public', secrets: [assistantsTokenKey] },
  async (req, res) => {
    res.setHeader('Cache-Control', 'no-store');
    res.setHeader('Pragma', 'no-cache');
    try {
      send(res, await route(req, res));
    } catch (error: unknown) {
      logger.error('assistant authorization server failed', {
        error: error instanceof Error ? error.message : String(error),
      });
      send(
        res,
        req.path === '/oauth/authorize'
          ? authorizeErrorPage('unavailable')
          : json(503, { error: 'temporarily_unavailable' }),
      );
    }
  },
);

/** Paths a client calls from a browser, where any origin may read the answer: none carries a cookie. */
const OPEN_TO_ANY_ORIGIN = [
  '/.well-known/oauth-protected-resource',
  '/.well-known/oauth-protected-resource/mcp',
  '/.well-known/oauth-authorization-server',
  '/oauth/token',
  '/oauth/register',
  '/oauth/revoke',
];

async function route(req: Request, res: Response): Promise<AuthReply> {
  const path = req.path.replace(/\/+$/, '');
  if (OPEN_TO_ANY_ORIGIN.includes(path)) {
    res.setHeader('Access-Control-Allow-Origin', '*');
    if (req.method === 'OPTIONS') {
      res.setHeader('Access-Control-Allow-Methods', 'GET, POST');
      res.setHeader(
        'Access-Control-Allow-Headers',
        'Content-Type, Authorization, MCP-Protocol-Version',
      );
      return json(204, {});
    }
  }
  const server = authorizationServer();
  const store = db();
  const now = new Date();
  const address = callerAddress(req);
  const get = req.method === 'GET';
  const post = req.method === 'POST';

  if (get && path.startsWith('/.well-known/oauth-protected-resource')) {
    return json(200, protectedResourceMetadata(server));
  }
  if (get && path.startsWith('/.well-known/oauth-authorization-server')) {
    return json(200, authorizationServerMetadata(server));
  }
  if (get && path === '/oauth/authorize') {
    const allowLocalDocuments = await clientDocumentsMayBeLocal(store);
    return authorize(
      {
        server,
        address,
        session: sessionFrom(req.headers.cookie),
        clients: {
          store,
          now,
          allowLoopbackRedirects: server.allowLoopbackRedirects,
          allowLocalDocuments,
          fetchDocument: clientDocumentFetch({ allowLocal: allowLocalDocuments }),
        },
      },
      req.query,
    );
  }
  if (post && path.startsWith('/oauth/consent/')) {
    return answerConsent(
      {
        store,
        server,
        now,
        address,
        verify: adminIdTokenVerifier,
        session: sessionFrom(req.headers.cookie),
      },
      path.slice('/oauth/consent/'.length),
      req.body,
    );
  }
  if (post && path === '/oauth/token') {
    return exchangeToken({ store, server, now, tokenKey: assistantsTokenKeyHere }, req.body);
  }
  if (post && path === '/oauth/register') {
    return registerClient(
      { store, address, now, allowLoopbackRedirects: server.allowLoopbackRedirects },
      req.body,
    );
  }
  if (post && path === '/oauth/revoke') {
    return revokeToken(store, req.body);
  }
  return json(get || post ? 404 : 405, { error: get || post ? 'not_found' : 'method_not_allowed' });
}

function send(res: Response, reply: AuthReply): void {
  switch (reply.kind) {
    case 'json':
      if (reply.status === 204) {
        res.status(204).end();
        return;
      }
      res.status(reply.status).json(reply.body);
      return;
    case 'page':
      res.setHeader('Content-Type', 'text/html; charset=utf-8');
      res.status(reply.status).send(reply.html);
      return;
    case 'redirect':
      if (reply.session !== undefined) {
        res.setHeader('Set-Cookie', sessionCookie(reply.session, AUTH_REQUEST_LIFETIME_MS / 1000));
      }
      res.setHeader('Location', reply.location);
      res.status(302).end();
      return;
  }
}
