import { readFileSync } from 'node:fs';
import { resolve } from 'node:path';

import { describe, expect, it } from 'vitest';

/**
 * The emulator ports are written down five times, in four files, and
 * `app/CLAUDE.md` says so out loud: "fixed in the root `firebase.json` and
 * mirrored in `lib/app/emulator_endpoint.dart`". The word *mirrored* is the
 * warning.
 *
 * They agree today. If one changes and the others do not, nothing fails
 * usefully: the app cannot reach a service that is running, the seed script
 * writes users nobody can sign in as, and a test suite connects to a port with
 * nothing on it and times out. Every one of those looks like a broken emulator
 * rather than a changed number.
 *
 * So `firebase.json` is the source and this checks the copies against it.
 */

const repoRoot = resolve(import.meta.dirname, '../../..');

function read(path: string): string {
  return readFileSync(resolve(repoRoot, path), 'utf8');
}

interface EmulatorConfig {
  emulators?: Record<string, { port?: number } | undefined>;
}

const config = JSON.parse(read('firebase.json')) as EmulatorConfig;

function portOf(service: string): number {
  const port = config.emulators?.[service]?.port;
  expect(port, `firebase.json declares no port for ${service}`).toBeTypeOf('number');
  return port as number;
}

const ports = {
  auth: portOf('auth'),
  firestore: portOf('firestore'),
  functions: portOf('functions'),
};

/** Every number in a file, so a port can be looked for without a shape. */
function numbersIn(source: string): Set<number> {
  return new Set(
    [...source.matchAll(/\b(\d{4,5})\b/g)].flatMap((match) =>
      match[1] === undefined ? [] : [Number(match[1])],
    ),
  );
}

describe('every copy of an emulator port matches firebase.json', () => {
  it('and firebase.json actually declares them', () => {
    expect(Object.values(ports).every((port) => port > 1024)).toBe(true);
    expect(new Set(Object.values(ports)).size).toBe(3);
  });

  const mirrors: [file: string, services: (keyof typeof ports)[]][] = [
    ['app/lib/app/emulator_endpoint.dart', ['auth', 'firestore', 'functions']],
    ['functions/test/emulator/emulator_harness.ts', ['auth', 'firestore', 'functions']],
    ['functions/test/rules/rules_harness.ts', ['firestore']],
    ['functions/tools/seed-emulator.mjs', ['auth']],
  ];

  for (const [file, services] of mirrors) {
    it(file, () => {
      const found = numbersIn(read(file));
      for (const service of services) {
        expect(
          found.has(ports[service]),
          `${file} does not carry the ${service} port ${String(ports[service])} ` +
            `that firebase.json declares — a mirror that has stopped mirroring ` +
            `looks like a broken emulator, not a changed number`,
        ).toBe(true);
      }
    });
  }

  it('and nothing mirrors a port firebase.json has never heard of', () => {
    // A stale port left behind after a change is the other half of the same
    // mistake, and the harder one to notice.
    const declared = new Set<number>(Object.values(ports));
    const uiPort = config.emulators?.['ui']?.port;
    if (typeof uiPort === 'number') declared.add(uiPort);

    const strays: string[] = [];
    for (const [file] of mirrors) {
      for (const candidate of numbersIn(read(file))) {
        // Only judge numbers that look like one of ours.
        if (candidate < 4000 || candidate > 9999) continue;
        if (!declared.has(candidate)) strays.push(`${file} carries ${String(candidate)}`);
      }
    }

    expect(strays, 'a port nothing runs on').toEqual([]);
  });
});
