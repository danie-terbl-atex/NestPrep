import { readFileSync, readdirSync } from 'node:fs';
import { resolve } from 'node:path';

import { describe, expect, it } from 'vitest';

/**
 * `BE-06`/`BE-07`: anything touching more than one document is a transaction,
 * and every write a callable makes is staged on it.
 *
 * These functions exist precisely because Security Rules cannot move several
 * documents at once. Redeeming an invite claims a member, adds a uid to the
 * household's role map, adds the household to the account and closes the
 * invite — four documents. A direct write among them is a household left half
 * joined, with no error anywhere: the call returns, and the person is a member
 * of a household that does not list them.
 *
 * And `BE-19`: a callable declares its timeout and its memory, so an infinite
 * loop is a bill for thirty seconds rather than for nine minutes.
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

const sources = sourcesIn(srcDir);

describe('every write a callable makes is atomic', () => {
  it('finds the source it is checking', () => {
    expect(sources.length).toBeGreaterThanOrEqual(10);
  });

  it('no document is written outside a transaction or a batch', () => {
    // Match the *call*, then look at what it is called on. Requiring a bare
    // word before the dot misses `householdRef(store, id).update(…)`, which is
    // the shape a direct write actually takes — that hole let a deliberately
    // broken version of this pass.
    const write = /\.(set|update|delete|create)\(/g;
    // `FieldValue.delete()` is a sentinel value handed to an update, not an
    // operation of its own.
    const allowed = ['transaction', 'batch', 'FieldValue', 'Timestamp'];
    const offences: string[] = [];

    for (const { name, source } of sources) {
      for (const match of source.matchAll(write)) {
        const before = source.slice(0, match.index);
        const receiver = /([\w$]+)$/.exec(before)?.[1] ?? '(an expression)';
        if (allowed.includes(receiver)) continue;
        const line = before.split('\n').length;
        offences.push(`${name}:${String(line)}  ${receiver}${match[0]}`);
      }
    }

    expect(
      offences,
      'a write outside the transaction leaves a household half changed, and ' +
        'nothing reports it — the call succeeds (BE-06, BE-07)',
    ).toEqual([]);
  });

  it('and the ones that move several documents say so in a comment', () => {
    // Not enforceable, but worth asserting the transaction is reached for the
    // file that moves the most: redeeming an invite touches four documents.
    const redeem = sources.find((file) => file.name.endsWith('redeem_invite.ts'));
    expect(redeem).toBeDefined();
    const source = redeem?.source ?? '';
    expect(source).toContain('runTransaction');
    expect(
      (source.match(/transaction\.(set|update|delete)\(/g) ?? []).length,
    ).toBeGreaterThanOrEqual(4);
  });
});

describe('every callable declares what it may cost', () => {
  const index = sources.find((file) => file.name === 'index.ts');

  // The limits themselves are asserted in `global_options.test.ts`, against the
  // endpoints the build actually produces.
  //
  // They used to be asserted *here*, by matching `setGlobalOptions({...})` in
  // this file's text — and that assertion passed for the life of the project
  // while every limit was `null` at runtime, because the call sat below the
  // `export ... from` lines and ES modules evaluate imports first. A test that
  // reads the source can only ever prove somebody typed the words. This one is
  // gone rather than moved, so there is one home for the fact (`ENG-01`).

  it('imports the module that sets the global options before anything else', () => {
    // What this file *can* still check is the ordering the runtime depends on:
    // the side-effect import has to come before the first callable export, or
    // the options are built too late again.
    const source = index?.source ?? '';
    const optionsAt = source.indexOf("import './shared/global_options'");
    const firstExportAt = source.indexOf('export {');
    expect(optionsAt, 'index.ts imports ./shared/global_options').toBeGreaterThanOrEqual(0);
    expect(
      optionsAt,
      'the options import must precede every callable export, or it sets nothing',
    ).toBeLessThan(firstExportAt);
  });

  it('and every exported callable is one we meant to ship', () => {
    // The list is the point: a Function is what rules cannot express, so a new
    // name here should have cost somebody an ADR to justify. Six were the
    // household's; the two documents ones are the household claim Storage rules
    // need and the folder-is-empty check no rule can perform (documents
    // ADR-0001).
    const exported = [...(index?.source ?? '').matchAll(/export \{ (\w+) \}/g)].flatMap((match) =>
      match[1] === undefined ? [] : [match[1]],
    );
    expect([...exported].sort()).toEqual([
      'createHousehold',
      'createInvite',
      'deleteDocumentFolder',
      'leaveHousehold',
      'redeemInvite',
      'removeMember',
      'setMemberRole',
      'syncDocumentAccess',
    ]);
  });
});
