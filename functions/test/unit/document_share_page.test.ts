import { readFileSync } from 'node:fs';
import { resolve } from 'node:path';

import { describe, expect, it } from 'vitest';

import { MARK_PATH } from '../../src/documents/share/document_share';
import {
  SHARE_PAGE_CSP,
  escapeHtml,
  renderSharePage,
  sharePageStatus,
  type SharePage,
} from '../../src/documents/share/share_page';
import { SHARE_PAGE_COPY, endsLabel } from '../../src/documents/share/share_page_copy';
import { DARK, LIGHT, SHARE_TOKEN_NAMES } from '../../src/documents/share/share_page_theme';
import { contentDispositionFor, isKeptContentType } from '../../src/documents/share/shared_file';

/**
 * The shared-link page (documents ADR-0006): the one NestPrep surface read by
 * somebody without the app. What it says, what it never says, and that its
 * colours and its mark are still the app's.
 */

const repoRoot = resolve(import.meta.dirname, '../../..');

const documentPage: SharePage = {
  kind: 'document',
  householdName: 'The Parkers',
  documentName: 'Medical aid card',
  isImage: true,
  endsLabel: 'Available until Tue 29 Sept, 18:00',
  fileQuery: '?t=abc&file=1',
};

describe('the page around a shared document', () => {
  it('names the document and who shared it, and shows an image inline', () => {
    const html = renderSharePage(documentPage);
    expect(html).toContain('Medical aid card');
    expect(html).toContain('The Parkers shared this with you');
    expect(html).toContain('<img class="document" src="?t=abc&amp;file=1"');
  });

  it('puts a PDF behind a button rather than inside the page', () => {
    const html = renderSharePage({ ...documentPage, isImage: false });
    expect(html).toContain(`<a class="button" href="?t=abc&amp;file=1">${SHARE_PAGE_COPY.openPdf}`);
    expect(html).not.toContain('<img class="document"');
  });

  it('never names the document in its title, which a chat preview reads', () => {
    const html = renderSharePage(documentPage);
    const title = /<title>(.*)<\/title>/.exec(html)?.[1] ?? '';
    expect(title).not.toContain('Medical');
    expect(title).toBe(escapeHtml(SHARE_PAGE_COPY.pageTitle));
  });

  it('escapes whatever a family typed as a name', () => {
    const html = renderSharePage({
      ...documentPage,
      documentName: '<script>alert(1)</script>',
      householdName: '"Quotes" & more',
    });
    expect(html).not.toContain('<script>');
    expect(html).toContain('&lt;script&gt;');
    expect(html).toContain('&quot;Quotes&quot; &amp; more');
  });

  it('carries no script, asks not to be indexed and sends no referrer', () => {
    const html = renderSharePage(documentPage);
    expect(html).not.toMatch(/<script/i);
    expect(html).toContain('<meta name="robots" content="noindex, nofollow">');
    expect(html).toContain('<meta name="referrer" content="no-referrer">');
    expect(SHARE_PAGE_CSP).toContain("default-src 'none'");
    expect(SHARE_PAGE_CSP).toContain("frame-ancestors 'none'");
    expect(SHARE_PAGE_CSP).not.toContain('script-src');
  });
});

describe('the PIN form', () => {
  it('asks for the PIN, posting back to the link itself', () => {
    const html = renderSharePage({ kind: 'pin', formQuery: '?t=abc', attemptsLeft: null });
    expect(html).toContain(SHARE_PAGE_COPY.pinTitle);
    expect(html).toContain('<form method="post" action="?t=abc">');
    expect(html).toContain('inputmode="numeric"');
    expect(html).not.toContain('role="alert"');
  });

  it('after a wrong PIN, says so and how many tries are left', () => {
    const html = renderSharePage({ kind: 'pin', formQuery: '?t=abc', attemptsLeft: 2 });
    expect(html).toContain('That PIN is not right. You have 2 tries left.');
    expect(SHARE_PAGE_COPY.wrongPin(1)).toBe('That PIN is not right. You have one try left.');
  });
});

describe('a link that does not open', () => {
  it('says why in words, with the status a browser expects', () => {
    const cases: [SharePage, string, number][] = [
      [{ kind: 'expired' }, SHARE_PAGE_COPY.expiredTitle, 410],
      [{ kind: 'ended' }, SHARE_PAGE_COPY.endedTitle, 410],
      [{ kind: 'locked' }, SHARE_PAGE_COPY.lockedTitle, 410],
      [{ kind: 'notFound' }, SHARE_PAGE_COPY.notFoundTitle, 404],
    ];
    for (const [page, title, status] of cases) {
      expect(renderSharePage(page), page.kind).toContain(title);
      expect(sharePageStatus(page), page.kind).toBe(status);
    }
    expect(sharePageStatus(documentPage)).toBe(200);
  });
});

describe('when a link ends, in words', () => {
  const expiresAt = new Date('2026-09-29T16:00:00Z');

  it("is on the household's clock", () => {
    const label = endsLabel({ expiresAt, untilShiftEnds: false, timeZone: 'Africa/Johannesburg' });
    expect(label).toContain('18:00');
    expect(label).toMatch(/^Available until /);
  });

  it('says the shift for a shift-bound link, with its hard stop', () => {
    const label = endsLabel({ expiresAt, untilShiftEnds: true, timeZone: 'UTC' });
    expect(label).toContain('until the shift ends');
    expect(label).toContain('16:00');
  });
});

describe('the file itself', () => {
  it('is one of the five kept types — the same list storage.rules enforces', () => {
    const storageRules = readFileSync(resolve(repoRoot, 'storage.rules'), 'utf8');
    const kept = /request\.resource\.contentType in \[([^\]]+)\]/.exec(storageRules)?.[1] ?? '';
    const listed = [...kept.matchAll(/'([^']+)'/g)].flatMap((match) => match[1] ?? []);
    expect(listed.length).toBe(5);
    for (const type of listed) expect(isKeptContentType(type), type).toBe(true);
    expect(isKeptContentType('text/html')).toBe(false);
    expect(isKeptContentType('image/svg+xml')).toBe(false);
  });

  it('is sent inline, under a name no header can be broken by', () => {
    const header = contentDispositionFor('Émile\'s "passport"\r\nX: y', 'application/pdf');
    expect(header).toMatch(/^inline; filename="[A-Za-z0-9 ._-]+\.pdf"; filename\*=UTF-8''/);
    expect(header).not.toMatch(/[\r\n]/);
    expect(header).toContain(encodeURIComponent('Émile'));
  });
});

describe("the page's look is still the app's", () => {
  const colours = readFileSync(resolve(repoRoot, 'app/lib/design/tokens/nest_colors.dart'), 'utf8');
  // The light block comes first in the Dart file and the dark second.
  const darkAt = colours.indexOf('canvas:', colours.indexOf('canvas:') + 1);
  const light = colours.slice(0, darkAt);
  const dark = colours.slice(darkAt);

  function tokenIn(block: string, name: string): string | undefined {
    const match = new RegExp(`\\b${name}: Color\\(0xFF([0-9A-Fa-f]{6})\\)`).exec(block);
    return match?.[1] === undefined ? undefined : `#${match[1].toUpperCase()}`;
  }

  for (const name of SHARE_TOKEN_NAMES) {
    it(`${name} matches the app's token in light and dark`, () => {
      expect(LIGHT[name], `light ${name}`).toBe(tokenIn(light, name));
      expect(DARK[name], `dark ${name}`).toBe(tokenIn(dark, name));
    });
  }

  it("the mark is a small copy of the app's nest, bundled with the Functions", () => {
    const mark = readFileSync(MARK_PATH);
    expect(mark.subarray(1, 4).toString('ascii')).toBe('PNG');
    const width = mark.readUInt32BE(16);
    expect(width).toBeLessThanOrEqual(256);
    expect(mark.length).toBeLessThan(100_000);
    // The source it is cut from (tools/brand/share_page_mark.sh) still exists.
    expect(
      readFileSync(resolve(repoRoot, 'app/assets/brand/nest_mark.png')).length,
    ).toBeGreaterThan(mark.length);
  });
});
