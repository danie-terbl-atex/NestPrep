import { readFileSync } from 'node:fs';
import { resolve } from 'node:path';

import { describe, expect, it } from 'vitest';

import { FEATURE_FLAGS, flagIsOn } from '../../src/shared/feature_flags';

/**
 * The V2 switches (foundation ADR-0014), as the server reads them — and the
 * same field names the app reads, from the one Dart enum that names them.
 */

describe('a V2 switch on the server', () => {
  it('is what the document says when it says anything', () => {
    expect(flagIsOn({ documentShareLinks: true }, 'documentShareLinks', false)).toBe(true);
    expect(flagIsOn({ documentShareLinks: false }, 'documentShareLinks', true)).toBe(false);
  });

  it('is on under the emulator and off in the cloud when the field is absent', () => {
    expect(flagIsOn(undefined, 'documentShareLinks', true)).toBe(true);
    expect(flagIsOn(undefined, 'documentShareLinks', false)).toBe(false);
    expect(flagIsOn({}, 'documentOfflineCopies', false)).toBe(false);
  });

  it('ignores a value that is not a boolean rather than guessing', () => {
    expect(flagIsOn({ documentShareLinks: 'yes' }, 'documentShareLinks', false)).toBe(false);
    expect(flagIsOn({ documentShareLinks: 1 }, 'documentShareLinks', true)).toBe(true);
  });
});

describe('the switches are named the same on both sides', () => {
  it('every server flag is a field of the app enum, and the other way round', () => {
    const dart = readFileSync(
      resolve(import.meta.dirname, '../../../app/lib/shared/flags/feature_flag.dart'),
      'utf8',
    );
    const fields = [...dart.matchAll(/\w+\('(\w+)'\)/g)].flatMap((match) => match[1] ?? []);
    expect([...fields].sort()).toEqual([...FEATURE_FLAGS].sort());
  });
});
