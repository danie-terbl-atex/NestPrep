import { readdirSync, readFileSync } from 'node:fs';
import { join } from 'node:path';

import { describe, expect, it } from 'vitest';

/**
 * A test that never runs is worse than no test, because it is counted.
 *
 * There are three vitest configs here, each pinned to its own folder, and a
 * test file only runs if some config's glob matches it. `emulator_ports` was
 * written as `emulator_ports_test.ts` while every config matches `*.test.ts`,
 * so it sat in the tree proving nothing until the suite total gave it away.
 *
 * Two ways to lose a test, and this checks both: the wrong filename, and the
 * right filename in a folder no config looks at.
 */

const PACKAGE_ROOT = join(__dirname, '..', '..');
const TEST_ROOT = join(PACKAGE_ROOT, 'test');

/** Every include glob, read from the configs rather than restated here. */
function declaredGlobs(): { config: string; glob: string }[] {
  const configs = readdirSync(PACKAGE_ROOT).filter(
    (name) => name.startsWith('vitest') && name.endsWith('.config.ts'),
  );
  return configs.flatMap((config) => {
    const source = readFileSync(join(PACKAGE_ROOT, config), 'utf8');
    const include = /include:\s*\[([^\]]*)\]/.exec(source);
    if (include === null) return [];
    return [...include[1].matchAll(/['"]([^'"]+)['"]/g)].map((match) => ({
      config,
      glob: match[1],
    }));
  });
}

function globToRegExp(glob: string): RegExp {
  const pattern = glob.replace(/\*\*\/|\*|[.+^${}()|[\]\\]/g, (token) => {
    if (token === '**/') return '(?:.*/)?';
    if (token === '*') return '[^/]*';
    return `\\${token}`;
  });
  return new RegExp(`^${pattern}$`);
}

/** Every .ts file under test/, as a path relative to the package root. */
function everyTestFile(): string[] {
  const walk = (dir: string): string[] =>
    readdirSync(dir, { withFileTypes: true }).flatMap((entry) => {
      const path = join(dir, entry.name);
      if (entry.isDirectory()) return walk(path);
      return entry.name.endsWith('.ts') ? [path] : [];
    });
  return walk(TEST_ROOT).map((path) => path.slice(PACKAGE_ROOT.length + 1));
}

/** Anything vitest would collect and run. */
const DECLARES_TESTS = /^\s*(it|test|describe)(\.\w+)?\(/m;

function hasTests(file: string): boolean {
  return DECLARES_TESTS.test(readFileSync(join(PACKAGE_ROOT, file), 'utf8'));
}

describe('every test file actually runs', () => {
  const globs = declaredGlobs();
  const files = everyTestFile();
  const matchers = globs.map(({ glob }) => globToRegExp(glob));
  const isCollected = (file: string): boolean => matchers.some((matcher) => matcher.test(file));

  it('found the configs and the files', () => {
    expect(globs.length).toBeGreaterThanOrEqual(3);
    expect(files.length).toBeGreaterThan(15);
  });

  it('every file with tests in it is matched by some config', () => {
    const skipped = files.filter((file) => hasTests(file) && !isCollected(file));

    expect(
      skipped,
      'these declare tests and no vitest config will run them — the filename ' +
        `must be *.test.ts and the folder one of: ${globs.map(({ glob }) => glob).join(', ')}`,
    ).toEqual([]);
  });

  it('and every file a config would run has tests in it', () => {
    const empty = files.filter((file) => isCollected(file) && !hasTests(file));

    expect(empty, 'a *.test.ts with no cases passes for ever and proves nothing').toEqual([]);
  });

  it('no file is claimed by two configs', () => {
    // The emulator and rules runs start different emulators. A file both would
    // collect passes under one command and fails under the other.
    const doubled = files.filter(
      (file) => matchers.filter((matcher) => matcher.test(file)).length > 1,
    );

    expect(doubled, 'it would run under two different emulator setups').toEqual([]);
  });
});
