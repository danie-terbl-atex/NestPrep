import { type Server, createServer } from 'node:http';
import type { AddressInfo } from 'node:net';

import { afterAll, beforeAll, describe, expect, it } from 'vitest';

import {
  CLIENT_DOCUMENT_MAX_BYTES,
  ClientDocumentUnavailable,
  clientDocumentFetch,
} from '../../../src/assistants/auth/client_document_fetch';

/**
 * The SSRF guard on a client's metadata document (assistants ADR-0002),
 * against a real socket on this machine: plain http and loopback are refused
 * unless the emulator escape is on, a private address is refused even then,
 * and a redirect, an oversized body or a slow server is a refusal, never a
 * partial answer.
 */

let server: Server;
let base = '';

beforeAll(async () => {
  server = createServer((req, res) => {
    if (req.url === '/client.json') {
      res.setHeader('Content-Type', 'application/json');
      res.end('{"client_id":"x"}');
    } else if (req.url === '/redirect') {
      res.writeHead(302, { Location: 'http://169.254.169.254/latest/meta-data' }).end();
    } else if (req.url === '/large') {
      res.end('x'.repeat(CLIENT_DOCUMENT_MAX_BYTES + 1));
    } else if (req.url === '/slow') {
      setTimeout(() => {
        res.end('{}');
      }, 500);
    } else {
      res.writeHead(404).end();
    }
  });
  await new Promise<void>((resolve) => server.listen(0, '127.0.0.1', resolve));
  base = `http://127.0.0.1:${String((server.address() as AddressInfo).port)}`;
});

afterAll(async () => {
  await new Promise<void>((resolve) => {
    server.close(() => {
      resolve();
    });
  });
});

async function reason(promise: Promise<string>): Promise<string> {
  try {
    await promise;
    return 'fetched';
  } catch (error) {
    if (error instanceof ClientDocumentUnavailable) return error.reason;
    throw error;
  }
}

describe('fetching a client document', () => {
  const local = clientDocumentFetch({ allowLocal: true, timeoutMs: 200 });
  const cloud = clientDocumentFetch({ allowLocal: false, timeoutMs: 200 });

  it('reads one from this machine only under the emulator escape', async () => {
    expect(await local(new URL(`${base}/client.json`))).toBe('{"client_id":"x"}');
    expect(await reason(cloud(new URL(`${base}/client.json`)))).toBe('scheme');
  });

  it('refuses a loopback name over https in the cloud, at the socket’s own lookup', async () => {
    expect(await reason(cloud(new URL('https://localhost:1/client.json')))).toBe('address');
  });

  it('refuses private, link-local and metadata addresses even under the escape', async () => {
    for (const host of ['10.0.0.1', '192.168.1.1', '169.254.169.254', '[fd00::1]']) {
      expect(await reason(local(new URL(`http://${host}/client.json`))), host).toBe('address');
    }
  });

  it('refuses an IP address for a host, however it is written, with or without the escape', async () => {
    for (const host of [
      '[::ffff:7f00:1]',
      '[::ffff:a9fe:a9fe]',
      '[64:ff9b::a9fe:a9fe]',
      '[2002:a9fe:a9fe::1]',
      '[::7f00:1]',
      '17.253.144.10',
      '[2606:4700::1111]',
    ]) {
      expect(await reason(cloud(new URL(`https://${host}:1/client.json`))), host).toBe('address');
    }
    expect(await reason(local(new URL(`http://[::ffff:a9fe:a9fe]:1/client.json`)))).toBe('address');
  });

  it('never follows a redirect', async () => {
    expect(await reason(local(new URL(`${base}/redirect`)))).toBe('status 302');
  });

  it('stops at 5 KB and at the timeout', async () => {
    expect(await reason(local(new URL(`${base}/large`)))).toBe('too large');
    expect(await reason(local(new URL(`${base}/slow`)))).toBe('timeout');
  });

  it('says a missing document is missing', async () => {
    expect(await reason(local(new URL(`${base}/nothing`)))).toBe('status 404');
  });
});
