import { describe, expect, it } from 'vitest';

import {
  DEFAULT_SETTINGS,
  isInsideWindow,
  readSettings,
  sendAfter,
  wantsCategory,
} from '../../../src/notifications/notification_settings';

/** One person's choices, read defensively and applied (notifications ADR-0003). */

describe('reading what a person chose', () => {
  it('a person who never chose gets the defaults: no digest, every reminder, quiet nights', () => {
    expect(readSettings(undefined)).toEqual(DEFAULT_SETTINGS);
    expect(DEFAULT_SETTINGS.digestEnabled).toBe(false);
    expect(DEFAULT_SETTINGS.categories).toEqual({ documents: true, handover: true, chores: true });
  });

  it('something that is not settings at all reads as the defaults, never as "everything"', () => {
    expect(readSettings('garbage')).toEqual(DEFAULT_SETTINGS);
    expect(readSettings({ digest: { enabled: 'yes' } })).toEqual(DEFAULT_SETTINGS);
  });

  it('a category a newer build added is ignored, and one missing is on', () => {
    const settings = readSettings({ categories: { handover: false, somethingNew: false } });
    expect(settings.categories).toEqual({ documents: true, handover: false, chores: true });
  });
});

describe('what a person wants to hear', () => {
  it('a switched-off category is not sent at all', () => {
    const settings = readSettings({ categories: { chores: false } });
    expect(wantsCategory(settings, 'chores')).toBe(false);
    expect(wantsCategory(settings, 'documents')).toBe(true);
  });

  it('the digest follows its own switch, and a test is always wanted', () => {
    expect(wantsCategory(DEFAULT_SETTINGS, 'digest')).toBe(false);
    expect(wantsCategory(readSettings({ digest: { enabled: true, minute: 390 } }), 'digest')).toBe(
      true,
    );
    expect(wantsCategory(DEFAULT_SETTINGS, 'test')).toBe(true);
  });
});

describe('quiet hours', () => {
  it('a window over midnight holds from its start to its end', () => {
    expect(isInsideWindow(22 * 60, 21 * 60, 6 * 60)).toBe(true);
    expect(isInsideWindow(3 * 60, 21 * 60, 6 * 60)).toBe(true);
    expect(isInsideWindow(6 * 60, 21 * 60, 6 * 60)).toBe(false);
    expect(isInsideWindow(12 * 60, 21 * 60, 6 * 60)).toBe(false);
  });

  it('a window inside one day holds too, and an empty one never does', () => {
    expect(isInsideWindow(13 * 60, 12 * 60, 14 * 60)).toBe(true);
    expect(isInsideWindow(9 * 60, 9 * 60, 9 * 60)).toBe(false);
  });

  it('a push at 23:00 in Johannesburg waits for 06:00 the next morning', () => {
    const now = new Date('2026-09-29T21:00:00Z');
    expect(sendAfter(DEFAULT_SETTINGS.quietHours, 'Africa/Johannesburg', now).toISOString()).toBe(
      '2026-09-30T04:00:00.000Z',
    );
  });

  it('a push at 03:00 waits for 06:00 the same morning', () => {
    const now = new Date('2026-09-30T01:00:00Z');
    expect(sendAfter(DEFAULT_SETTINGS.quietHours, 'Africa/Johannesburg', now).toISOString()).toBe(
      '2026-09-30T04:00:00.000Z',
    );
  });

  it('outside quiet hours, or with them off, it goes now', () => {
    const noon = new Date('2026-09-29T10:00:00Z');
    expect(sendAfter(DEFAULT_SETTINGS.quietHours, 'Africa/Johannesburg', noon)).toEqual(noon);
    const night = new Date('2026-09-29T21:00:00Z');
    const off = { ...DEFAULT_SETTINGS.quietHours, enabled: false };
    expect(sendAfter(off, 'Africa/Johannesburg', night)).toEqual(night);
  });
});
