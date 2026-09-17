import { describe, expect, it } from 'vitest';

import { parsePingRequest, pong } from '../src/diagnostics/pong';

describe('parsePingRequest', () => {
  it('rejects a body that is not an object', () => {
    expect(() => parsePingRequest('hello')).toThrow('A ping needs a body.');
  });

  it('rejects a missing or empty sentFrom', () => {
    expect(() => parsePingRequest({})).toThrow('where it came from');
    expect(() => parsePingRequest({ sentFrom: '' })).toThrow('where it came from');
  });

  it('keeps only the fields it knows', () => {
    expect(parsePingRequest({ sentFrom: 'android', extra: 1 })).toEqual({ sentFrom: 'android' });
  });
});

describe('pong', () => {
  it('echoes the sender with the server time as an ISO instant', () => {
    const now = new Date('2026-09-17T18:00:00.000Z');
    expect(pong({ sentFrom: 'ios' }, now)).toEqual({
      echo: 'ios',
      receivedAt: '2026-09-17T18:00:00.000Z',
    });
  });
});
