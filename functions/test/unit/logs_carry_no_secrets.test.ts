import { readFileSync, readdirSync } from 'node:fs';
import { resolve } from 'node:path';

import { describe, expect, it } from 'vitest';

/**
 * `ENG-22` / `BE-13`: a log line carries ids and counts, never a secret or a
 * person's contact details — part of Stage C's security pass (accounts
 * ADR-0006). Reviewing every `logger` call once found none; this keeps it so.
 *
 * It reads each `logger.<level>(message, { … })` in `src/` and refuses a
 * field whose *name* says it is a credential or a person. It cannot see what
 * a well-named field holds, so it is a floor, not a proof — which is why the
 * list of names is generous.
 */

const srcDir = resolve(import.meta.dirname, '../../src');

function sourcesIn(dir: string): { name: string; source: string }[] {
  return readdirSync(dir, { withFileTypes: true }).flatMap((entry) => {
    const path = resolve(dir, entry.name);
    if (entry.isDirectory()) return sourcesIn(path);
    if (!entry.name.endsWith('.ts')) return [];
    return [{ name: path.slice(srcDir.length + 1), source: readFileSync(path, 'utf8') }];
  });
}

/** The text of every logger call's arguments, found by matching its parentheses. */
function loggerCalls(source: string): string[] {
  const calls: string[] = [];
  for (const match of source.matchAll(/logger\.(?:debug|info|warn|error|log)\(/g)) {
    let depth = 1;
    let end = match.index + match[0].length;
    while (depth > 0 && end < source.length) {
      const char = source[end];
      if (char === '(') depth += 1;
      if (char === ')') depth -= 1;
      end += 1;
    }
    calls.push(source.slice(match.index + match[0].length, end - 1));
  }
  return calls;
}

/** The field names an object literal in a logger call passes. */
function loggedFields(call: string): string[] {
  const object = call.slice(call.indexOf('{'));
  if (!call.includes('{')) return [];
  return [...object.matchAll(/(?:[{,]\s*)(\.\.\.)?([A-Za-z_$][\w$]*)\s*(?=[:,}])/g)].flatMap(
    (match) => (match[2] === undefined ? [] : [match[2]]),
  );
}

const FORBIDDEN =
  /^(email|emails|address|ip|phone|password|token|idToken|refreshToken|accessToken|credential|secret|code|storeRef|purchaseToken|verificationData|signedPayload|displayName|name|body|data|message)$/i;

const sources = sourcesIn(srcDir);

describe('what the Functions log', () => {
  it('finds logger calls to check', () => {
    const count = sources.reduce((sum, file) => sum + loggerCalls(file.source).length, 0);
    expect(count).toBeGreaterThanOrEqual(30);
  });

  it('never logs a field named for a credential or a person', () => {
    const offences = sources.flatMap(({ name, source }) =>
      loggerCalls(source).flatMap((call) =>
        loggedFields(call)
          .filter((field) => FORBIDDEN.test(field))
          .map((field) => `${name}: ${field}`),
      ),
    );
    expect(offences).toEqual([]);
  });

  it('never logs a whole request body or a raw error object', () => {
    const offences = sources.flatMap(({ name, source }) =>
      loggerCalls(source)
        .filter((call) => /request\.data|req\.body|rawRequest|\bheaders\b/.test(call))
        .map((call) => `${name}: ${call.slice(0, 60)}`),
    );
    expect(offences).toEqual([]);
  });

  it('the checker itself sees a forbidden field when there is one', () => {
    expect(loggedFields("'x', { householdId, email: user.email }")).toContain('email');
    expect(loggedFields("'x', { token }")).toContain('token');
  });
});
