import { describe, expect, it } from 'vitest';
import { z } from 'zod';

import { ASSISTANT_SCOPES } from '../../../src/assistants/assistant_scopes';
import {
  insufficientScopeChallenge,
  invalidTokenChallenge,
} from '../../../src/assistants/mcp/mcp_handler';
import { ASSISTANT_TOOLS } from '../../../src/assistants/mcp/tools';
import {
  calendarDate,
  minuteOf,
  recurrenceInput,
  timeOf,
  wallClockTime,
} from '../../../src/assistants/mcp/validators';

/**
 * The tool table as a host reads it (assistants ADR-0001): the exact v1
 * names, each with the scope, hints and schemas the spec asks for, and the
 * challenges the HTTP layer sends.
 */

const EXPECTED: [name: string, scope: string, readOnly: boolean, destructive: boolean][] = [
  ['get_household', 'household:read', true, false],
  ['list_events', 'calendar:read', true, false],
  ['create_event', 'calendar:write', false, false],
  ['update_event', 'calendar:write', false, true],
  ['delete_event', 'calendar:write', false, true],
  ['get_grocery_list', 'lists:read', true, false],
  ['add_grocery_items', 'lists:write', false, false],
  ['update_grocery_item', 'lists:write', false, true],
  ['tick_grocery_items', 'lists:write', false, false],
  ['remove_grocery_items', 'lists:write', false, true],
];

describe('the v1 tools', () => {
  it('are exactly these, in this order, with these scopes and hints', () => {
    expect(
      ASSISTANT_TOOLS.map((tool) => [
        tool.name,
        tool.scope,
        tool.annotations.readOnlyHint,
        tool.annotations.destructiveHint,
      ]),
    ).toEqual(EXPECTED);
  });

  for (const tool of ASSISTANT_TOOLS) {
    describe(tool.name, () => {
      it('has a name a host accepts and a title', () => {
        expect(tool.name.length).toBeLessThanOrEqual(64);
        expect(tool.name).toMatch(/^[a-z][a-z_]*$/);
        expect(tool.title.length).toBeGreaterThan(0);
      });

      it('says every hint as a boolean, and never reaches outside NestPrep', () => {
        for (const hint of Object.values(tool.annotations)) expect(typeof hint).toBe('boolean');
        expect(tool.annotations.openWorldHint).toBe(false);
        expect(Object.keys(tool.annotations).sort()).toEqual([
          'destructiveHint',
          'idempotentHint',
          'openWorldHint',
          'readOnlyHint',
        ]);
      });

      it('refuses arguments it does not name', () => {
        const schema = z.toJSONSchema(tool.input, { io: 'input' });
        expect(schema['additionalProperties']).toBe(false);
        expect(tool.input.safeParse({ householdId: 'h-other' }).success).toBe(false);
      });

      it('takes no household, member or author from the assistant', () => {
        const keys = JSON.stringify(z.toJSONSchema(tool.input, { io: 'input' }));
        for (const forbidden of [
          'household_id',
          'householdId',
          'created_by',
          'createdBy',
          'added_by',
          'addedBy',
          'via',
        ]) {
          expect(keys).not.toContain(`"${forbidden}"`);
        }
      });

      it('has an output schema and a description written for the model', () => {
        expect(z.toJSONSchema(tool.output)['type']).toBe('object');
        expect(tool.description.length).toBeGreaterThan(120);
        expect(tool.description).toMatch(/NestPrep/);
      });
    });
  }

  it('every tool that takes a day says YYYY-MM-DD, and every one that takes a time says the wall clock', () => {
    for (const tool of ASSISTANT_TOOLS) {
      const schema = JSON.stringify(z.toJSONSchema(tool.input, { io: 'input' }));
      if (schema.includes('"date"') || schema.includes('"from"')) {
        expect(tool.description, tool.name).toMatch(/YYYY-MM-DD/);
      }
      if (schema.includes('start_time')) {
        expect(tool.description, tool.name).toMatch(/wall clock/);
      }
    }
  });
});

describe('the challenges', () => {
  const origin = 'https://nestprep-643b7.web.app';

  it('401 without a token names the metadata and every scope', () => {
    expect(invalidTokenChallenge(origin, false)).toBe(
      'Bearer resource_metadata="https://nestprep-643b7.web.app/.well-known/oauth-protected-resource/mcp", ' +
        `scope="${ASSISTANT_SCOPES.join(' ')}"`,
    );
  });

  it('401 with a bad token adds invalid_token', () => {
    expect(invalidTokenChallenge(origin, true)).toBe(
      'Bearer error="invalid_token", resource_metadata="https://nestprep-643b7.web.app/.well-known/oauth-protected-resource/mcp", ' +
        `scope="${ASSISTANT_SCOPES.join(' ')}"`,
    );
  });

  it('403 names the one scope needed', () => {
    expect(insufficientScopeChallenge(origin, 'lists:write')).toBe(
      'Bearer error="insufficient_scope", scope="lists:write", resource_metadata="https://nestprep-643b7.web.app/.well-known/oauth-protected-resource/mcp"',
    );
  });
});

describe('the values the tools accept', () => {
  it('a day is a real calendar day', () => {
    for (const day of ['2026-11-07', '2028-02-29'])
      expect(calendarDate.safeParse(day).success).toBe(true);
    for (const day of ['2026-02-29', '2026-13-01', '2026-11-7', '7 Nov', '2026-11-07T00:00']) {
      expect(calendarDate.safeParse(day).success, day).toBe(false);
    }
  });

  it('a time is 24-hour HH:MM, and minutes go both ways', () => {
    for (const time of ['00:00', '07:30', '23:59']) {
      expect(wallClockTime.safeParse(time).success).toBe(true);
      expect(timeOf(minuteOf(time))).toBe(time);
    }
    for (const time of ['24:00', '7:30', '07:60', '3pm']) {
      expect(wallClockTime.safeParse(time).success, time).toBe(false);
    }
    expect(minuteOf('14:00')).toBe(840);
  });

  it("a repeat is what the Dart rule can expand, with the Dart rule's defaults", () => {
    expect(recurrenceInput.parse({ frequency: 'daily' })).toEqual({
      frequency: 'daily',
      interval: 1,
      weekdays: [],
      until: null,
    });
    for (const rule of [
      { frequency: 'weekly', interval: 0 },
      { frequency: 'weekly', interval: 367 },
      { frequency: 'weekly', weekdays: [8] },
      { frequency: 'weekly', weekdays: [1, 1] },
      { frequency: 'monthly', weekdays: [1] },
      { frequency: 'weekly', until: '2026-02-30' },
      { frequency: 'yearly' },
      { frequency: 'weekly', byDay: 'MO' },
    ]) {
      expect(recurrenceInput.safeParse(rule).success, JSON.stringify(rule)).toBe(false);
    }
  });
});
