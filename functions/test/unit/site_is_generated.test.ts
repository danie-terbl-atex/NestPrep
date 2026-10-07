import { execFileSync } from 'node:child_process';
import { readFileSync } from 'node:fs';
import { resolve } from 'node:path';

import { describe, expect, it } from 'vitest';

import { parseBlocks, parseDocument, renderInline } from '../../../hosting/tools/site-markdown.mjs';
import { LEGAL_DOCUMENTS, buildSite } from '../../../hosting/tools/site-pages.mjs';

/**
 * The public site (`hosting/`) is generated into `hosting/public/` and
 * committed, like the rules files. Its privacy policy and terms are rendered
 * from the same `app/assets/legal/*.md` the app bundles, so a policy edited
 * without a build would have the app and the website saying different things
 * about the same person's data — the one place that must never happen.
 */

const repoRoot = resolve(__dirname, '../../..');
const builder = resolve(repoRoot, 'hosting/tools/build-site.mjs');
const site = buildSite(repoRoot);

const pages = [...site]
  .filter(([path]) => path.endsWith('.html'))
  .map(([path, contents]) => ({ path, html: String(contents) }));

const read = (path: string): string => readFileSync(resolve(repoRoot, path), 'utf8');

describe('the public site is generated', () => {
  it('and hosting/public is exactly what the builder produces', () => {
    expect(() =>
      execFileSync(process.execPath, [builder, '--check'], { stdio: 'pipe' }),
    ).not.toThrow();
  });

  it('with the landing page, both legal documents, the deletion and invite pages and a 404', () => {
    expect(pages.map((page) => page.path).sort()).toEqual([
      '404.html',
      'delete-account/index.html',
      'index.html',
      'invite/index.html',
      'privacy/index.html',
      'terms/index.html',
    ]);
  });

  it('and is deployed from there, checked first, with the deletion request routed to its Function', () => {
    const firebase = JSON.parse(read('firebase.json')) as {
      hosting: {
        public: string;
        predeploy: string[];
        rewrites: object[];
      };
    };
    expect(firebase.hosting.public).toBe('hosting/public');
    expect(firebase.hosting.predeploy).toContain('node hosting/tools/build-site.mjs --check');
    expect(firebase.hosting.rewrites).toContainEqual({
      source: '/api/account-deletion-request',
      function: { functionId: 'requestAccountDeletion', region: 'europe-west1' },
    });
  });
});

describe('every page', () => {
  for (const { path, html } of pages) {
    it(`${path} links the privacy policy, the terms and account deletion`, () => {
      for (const target of ['/privacy', '/terms', '/delete-account']) {
        expect(html).toContain(`href="${target}"`);
      }
    });

    it(`${path} loads nothing from another origin, so the site sets no third-party cookie`, () => {
      const loads = [...html.matchAll(/(?:src|<link[^>]*href)="([^"]+)"/g)].map((m) => m[1]);
      expect(loads.length).toBeGreaterThan(0);
      for (const url of loads) expect(url, url).toMatch(/^\/[^/]/);
    });

    it(`${path} has no inline script, style or handler, which the CSP would refuse`, () => {
      expect(html).not.toMatch(/<script(?![^>]*\ssrc=)[^>]*>/);
      expect(html).not.toMatch(/\sstyle="/);
      expect(html).not.toMatch(/\son[a-z]+="/);
    });

    it(`${path} has one h1, a skip link to main, and a language`, () => {
      expect(html.match(/<h1[\s>]/g)).toHaveLength(1);
      expect(html).toContain('href="#main"');
      expect(html).toContain('<main id="main"');
      expect(html).toContain('<html lang="en-ZA">');
    });
  }

  it('the stylesheet loads nothing from another origin either', () => {
    const css = read('hosting/src/site.css');
    for (const match of css.matchAll(/url\('([^']+)'\)/g)) expect(match[1]).toMatch(/^\/[^/]/);
    expect(css).not.toContain('@import');
  });
});

describe('the legal documents', () => {
  for (const legal of LEGAL_DOCUMENTS) {
    const document = parseDocument(read(legal.source));

    it(`${legal.source} has a title and a whole-number version the app can record`, () => {
      expect(document.title.length).toBeGreaterThan(0);
      expect(Number.isInteger(document.version)).toBe(true);
      expect(document.updated).toMatch(/^\d{4}-\d{2}-\d{2}$/);
    });

    it(`${legal.source} says it is a draft until legal review has happened`, () => {
      expect(read(legal.source)).toContain('DRAFT FOR LEGAL REVIEW');
    });

    it(`${legal.source} renders with no markdown left over`, () => {
      const html = String(site.get(legal.output));
      expect(html).not.toContain('](');
      expect(html).not.toContain('**');
      expect(html).toContain(`Version ${String(document.version)}`);
    });
  }
});

describe('the legal markdown renderer', () => {
  it('escapes everything a document could smuggle in', () => {
    expect(renderInline('<script>alert("x")</script> & co')).toBe(
      '&lt;script&gt;alert(&quot;x&quot;)&lt;/script&gt; &amp; co',
    );
  });

  it('links only to web and mail addresses', () => {
    expect(renderInline('[the Regulator](https://inforegulator.org.za)')).toBe(
      '<a href="https://inforegulator.org.za">the Regulator</a>',
    );
    expect(renderInline('[write](mailto:a@b.co)')).toBe('<a href="mailto:a@b.co">write</a>');
    expect(renderInline('[click](javascript:alert(1))')).not.toContain('<a');
  });

  it('marks a placeholder so a draft cannot pass for the finished text', () => {
    expect(renderInline('by [legal entity name], of **[address]**')).toBe(
      'by <mark class="placeholder">[legal entity name]</mark>, of ' +
        '<strong><mark class="placeholder">[address]</mark></strong>',
    );
  });

  it('reads headings, wrapped paragraphs and one level of bullets', () => {
    expect(parseBlocks('## One\nfirst line\nsecond line\n\n- a\n- b\n### Two')).toEqual([
      { kind: 'heading', text: 'One' },
      { kind: 'paragraph', text: 'first line second line' },
      { kind: 'list', items: ['a', 'b'] },
      { kind: 'subheading', text: 'Two' },
    ]);
  });

  it('refuses what the app renderer cannot draw', () => {
    for (const outside of ['1. numbered', '| a | table |', '# a title', '* star', '> quote']) {
      expect(() => parseBlocks(outside), outside).toThrow();
    }
  });

  it('refuses a document without a whole-number version', () => {
    expect(() => parseDocument('---\ntitle: X\nversion: 1.5\n---\nText')).toThrow();
    expect(() => parseDocument('No front matter')).toThrow();
  });
});

describe('the deletion page and its script agree with the request contract', () => {
  const page = read('hosting/src/pages/delete-account.html');
  const script = read('hosting/src/delete-account.js');

  it('posts to the rewritten endpoint', () => {
    expect(script).toContain("'/api/account-deletion-request'");
    expect(script).toContain("method: 'POST'");
  });

  it('has words in the page for every state the script can show', () => {
    const states = [...script.matchAll(/return '([a-zA-Z]+)';|show\('([a-zA-Z]+)'\)/g)].map(
      (match) => match[1] ?? match[2],
    );
    for (const state of [...states, 'received', 'offline']) {
      expect(page, state).toContain(`data-state="${String(state)}"`);
    }
  });

  it('keeps the form hidden without JavaScript and says what to do instead', () => {
    expect(page).toMatch(/<form[^>]*\shidden[\s>]/);
    expect(page).toContain('<noscript>');
  });
});

describe('an invite link opens the app or says how to join (household ADR-0005)', () => {
  const page = read('hosting/src/pages/invite.html');
  const script = read('hosting/src/invite.js');
  const firebase = JSON.parse(read('firebase.json')) as { hosting: { rewrites: object[] } };
  const manifest = read('app/android/app/src/main/AndroidManifest.xml');

  it('serves every /invite/<code> from the one page, and the app links file from a path Hosting does not ignore', () => {
    expect(firebase.hosting.rewrites).toContainEqual({
      source: '/invite/**',
      destination: '/invite/index.html',
    });
    expect(firebase.hosting.rewrites).toContainEqual({
      source: '/.well-known/assetlinks.json',
      destination: '/well-known/assetlinks.json',
    });
  });

  it('has words in the page for every state the script can show', () => {
    const states = [...script.matchAll(/show\('([a-zA-Z]+)'\)/g)].map((match) => match[1]);
    expect(states.length).toBeGreaterThan(1);
    for (const state of states) expect(page, state).toContain(`data-state="${String(state)}"`);
  });

  it('opens the app through the scheme the manifest declares', () => {
    expect(script).toContain('nestprep://invite/');
    expect(manifest).toContain('android:scheme="nestprep"');
    expect(manifest).toContain('android:pathPrefix="/invite/"');
  });

  it('checks a code against the same letters the server draws from', () => {
    const alphabet = /READABLE_ALPHABET = '([A-Z0-9]+)'/.exec(
      read('functions/src/shared/readable_code.ts'),
    )?.[1];
    expect(script).toContain(`'${String(alphabet)}'`);
  });

  it('vouches for the app the manifest builds', () => {
    const links = JSON.parse(String(site.get('well-known/assetlinks.json'))) as {
      target: { package_name: string; sha256_cert_fingerprints: string[] };
    }[];
    const applicationId = /applicationId = "([^"]+)"/.exec(
      read('app/android/app/build.gradle.kts'),
    )?.[1];
    expect(links[0]?.target.package_name).toBe(applicationId);
    expect(links[0]?.target.sha256_cert_fingerprints.length).toBeGreaterThan(0);
  });
});

describe('the site wears the app colours', () => {
  /**
   * The opaque tokens of one palette in nest_colors.dart, written either as
   * `name: Color(0xFFRRGGBB)` or as `name: oat` naming a `static const` colour.
   */
  function dartPalette(name: 'light' | 'dark'): Map<string, string> {
    const source = read('app/lib/design/tokens/nest_colors.dart');
    const named = new Map(
      [...source.matchAll(/static const (\w+) = Color\(0xFF([0-9A-Fa-f]{6})\);/g)].map((m) => [
        String(m[1]),
        String(m[2]),
      ]),
    );
    const start = source.indexOf(`static const ${name} = NestColors(`);
    const block = source.slice(start, source.indexOf(');', start));
    return new Map(
      [...block.matchAll(/(\w+): (?:Color\(0xFF([0-9A-Fa-f]{6})\)|(\w+),)/g)].flatMap((m) => {
        const hex = m[2] ?? (m[3] === undefined ? undefined : named.get(m[3]));
        return hex === undefined ? [] : [[String(m[1]), `#${hex.toLowerCase()}`] as const];
      }),
    );
  }

  function cssPalette(block: string): Map<string, string> {
    return new Map(
      [...block.matchAll(/--color-([a-z-]+): (#[0-9a-f]{6});/g)].map((m) => [
        String(m[1]).replace(/-([a-z])/g, (_, letter: string) => letter.toUpperCase()),
        String(m[2]),
      ]),
    );
  }

  const css = read('hosting/src/site.css');
  const darkStart = css.indexOf('@media (prefers-color-scheme: dark)');

  for (const [theme, block] of [
    ['light', css.slice(0, darkStart)],
    ['dark', css.slice(darkStart)],
  ] as const) {
    it(`every ${theme} colour is the app's own token of the same name (ENG-25)`, () => {
      const app = dartPalette(theme);
      const site = cssPalette(block);
      expect(site.size).toBeGreaterThan(15);
      for (const [token, hex] of site) expect(hex, token).toBe(app.get(token));
    });
  }
});
