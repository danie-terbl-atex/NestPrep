import { execFileSync } from 'node:child_process';
import { readFileSync } from 'node:fs';
import { resolve } from 'node:path';

import { describe, expect, it } from 'vitest';

import { parseBlocks, parseDocument, renderInline } from '../../../hosting/tools/site-markdown.mjs';
import {
  FIREBASE_WEB_SDK,
  LEGAL_DOCUMENTS,
  buildSite,
} from '../../../hosting/tools/site-pages.mjs';
import { ASSISTANT_SCOPES } from '../../src/assistants/assistant_scopes';
import { WEB_ERROR_STATUS } from '../../src/premium_vouchers/premium_web_answer';

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

  it('with the landing page, both legal documents, the deletion, invite, connect, Premium and redeem pages and a 404', () => {
    expect(pages.map((page) => page.path).sort()).toEqual([
      '404.html',
      'connect/index.html',
      'delete-account/index.html',
      'index.html',
      'invite/index.html',
      'premium/index.html',
      'privacy/index.html',
      'redeem/index.html',
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

describe('the Premium gift page and the redeem page (subscriptions ADR-0003, ADR-0004)', () => {
  const firebase = JSON.parse(read('firebase.json')) as {
    hosting: {
      rewrites: object[];
      headers: { source: string; headers: { key: string; value: string }[] }[];
    };
  };
  const giftPage = read('hosting/src/pages/premium.html');
  const giftScript = read('hosting/src/premium.js');
  const redeemPage = read('hosting/src/pages/redeem.html');
  const redeemScript = read('hosting/src/redeem.js');

  const regionOf = (page: string, id: string): string => {
    const start = page.indexOf(`id="${id}"`);
    expect(start, id).toBeGreaterThan(0);
    return page.slice(start);
  };
  const quotedIn = (source: string, pattern: RegExp): string[] =>
    [...source.matchAll(pattern)].flatMap((match) => (match[1] === undefined ? [] : [match[1]]));

  it('reaches premiumWeb through the rewrite, and serves every gift link from the one page', () => {
    expect(firebase.hosting.rewrites).toContainEqual({
      source: '/api/premium/**',
      function: { functionId: 'premiumWeb', region: 'europe-west1' },
    });
    expect(firebase.hosting.rewrites).toContainEqual({
      source: '/premium/**',
      destination: '/premium/index.html',
    });
    const rewriteSources = firebase.hosting.rewrites.map(
      (rewrite) => (rewrite as { source: string }).source,
    );
    expect(rewriteSources.indexOf('/api/premium/**')).toBeLessThan(
      rewriteSources.indexOf('/premium/**'),
    );
  });

  it('answers the API with no-store, and the gift page with no-store and no referrer', () => {
    const headersFor = (path: string): { key: string; value: string }[] =>
      firebase.hosting.headers
        .filter((block) =>
          block.source
            .replace(/^\{|\}$/g, '')
            .split(',')
            .includes(path),
        )
        .flatMap((block) => block.headers);
    expect(headersFor('/api/premium/**')).toContainEqual({
      key: 'Cache-Control',
      value: 'no-store',
    });
    for (const path of ['/premium', '/premium/**']) {
      expect(headersFor(path), path).toContainEqual({ key: 'Cache-Control', value: 'no-store' });
      expect(headersFor(path), path).toContainEqual({
        key: 'Referrer-Policy',
        value: 'no-referrer',
      });
    }
  });

  it('the gift page posts to the two gift endpoints and never sends the token anywhere else', () => {
    expect(giftScript).toContain("'/api/premium/gift/lookup'");
    expect(giftScript).toContain("'/api/premium/gift/reassign'");
    expect(giftScript).toContain("method: 'POST'");
    expect(giftScript).toContain("referrerPolicy: 'no-referrer'");
    expect(giftScript).toContain('[A-Za-z0-9_-]{43}');
  });

  it('the gift page has words for every state its script can show', () => {
    const gift = regionOf(giftPage, 'gift-status');
    const giftStates = [
      ...quotedIn(giftScript, /showGift\('([a-zA-Z]+)'/g),
      ...quotedIn(/LOOKUP_STATES = \[([^\]]*)\]/.exec(giftScript)?.[1] ?? '', /'([a-zA-Z]+)'/g),
      ...quotedIn(/REFUSALS = \{([^}]*)\}/.exec(giftScript)?.[1] ?? '', /: '([a-zA-Z]+)'/g),
      'unavailable',
      'offline',
    ].filter((state) => state !== 'badEmail');
    expect(giftStates).toEqual(expect.arrayContaining(['loading', 'waiting', 'claimed', 'void']));
    for (const state of giftStates) expect(gift, state).toContain(`data-state="${state}"`);

    const form = regionOf(giftPage, 'gift-form-status');
    const formStates = [
      ...quotedIn(giftScript, /show\(formStatus, '([a-zA-Z]+)'/g),
      'badEmail',
      'tooMany',
      'unavailable',
      'offline',
    ];
    expect(formStates).toContain('sent');
    for (const state of formStates) expect(form, state).toContain(`data-state="${state}"`);
  });

  it('the redeem page posts to the redeem endpoint and has words for every result and refusal', () => {
    expect(redeemScript).toContain("'/api/premium/redeem'");
    expect(redeemScript).toContain("method: 'POST'");
    const listed = (name: string): string[] =>
      quotedIn(
        new RegExp(`${name} = \\[([^\\]]*)\\]`).exec(redeemScript)?.[1] ?? '',
        /'([a-zA-Z]+)'/g,
      );
    const states = [
      ...listed('RESULTS'),
      ...listed('REFUSALS'),
      'tooMany',
      'unavailable',
      'offline',
    ];
    expect(states).toEqual(expect.arrayContaining(['redeemed', 'alreadyRedeemed', 'codeUsedUp']));
    const status = regionOf(redeemPage, 'redeem-status');
    for (const state of states) expect(status, state).toContain(`data-state="${state}"`);
  });

  it('the scripts know every refusal premiumWeb gives on their paths', () => {
    const gift = ['voucherNotFound', 'voucherClaimed', 'voucherVoid', 'badEmail', 'tooManyTries'];
    const redeem = [
      'codeUnknown',
      'codeNotStarted',
      'codeExpired',
      'codePaused',
      'codeUsedUp',
      'badEmail',
      'badCode',
    ];
    const giftRefusals = /REFUSALS = \{([^}]*)\}/.exec(giftScript)?.[1] ?? '';
    const redeemRefusals = /REFUSALS = \[([^\]]*)\]/.exec(redeemScript)?.[1] ?? '';
    for (const error of [...gift, ...redeem]) expect(WEB_ERROR_STATUS, error).toHaveProperty(error);
    for (const error of gift) expect(giftRefusals, error).toContain(`${error}:`);
    for (const error of redeem) expect(redeemRefusals, error).toContain(`'${error}'`);
    expect(WEB_ERROR_STATUS.tooManyTries).toBe(429);
    expect(redeemScript).toContain('response.status === 429');
    expect(giftScript).toContain('response.status === 429');
  });

  it('keeps both forms hidden without JavaScript and says what to do instead', () => {
    for (const page of [giftPage, redeemPage]) {
      expect(page).toMatch(/<form[^>]*\shidden[\s>]/);
      expect(page).toContain('<noscript>');
    }
  });

  it('the redeem page links to no store, so it never reads as buying in the app', () => {
    const built = String(site.get('redeem/index.html'));
    expect(built).not.toMatch(/apps\.apple\.com|play\.google\.com|itunes\.apple\.com/);
  });
});

describe('the consent page an assistant sends a member to (assistants ADR-0002)', () => {
  const page = read('hosting/src/pages/connect.html');
  const script = read('hosting/src/connect.js');
  const firebase = JSON.parse(read('firebase.json')) as {
    hosting: {
      rewrites: object[];
      headers: { source: string; headers: { key: string; value: string }[] }[];
    };
  };
  const built = String(site.get('connect/index.html'));

  it('says, just above Allow, to continue only from one’s own assistant', () => {
    const warning = built.indexOf(
      'Only continue if you just chose Connect in your own Claude or ChatGPT.',
    );
    expect(warning).toBeGreaterThan(0);
    expect(built.indexOf('type="submit">Allow</button>', warning)).toBeGreaterThan(warning);
  });

  it('offers a labelled switch for every scope, and only those', () => {
    const offered = [...page.matchAll(/data-scope="([a-z:]+)"/g)].map((match) => match[1]);
    expect(offered.sort()).toEqual([...ASSISTANT_SCOPES].sort());
    for (const scope of ASSISTANT_SCOPES) {
      expect(page).toMatch(new RegExp(`value="${scope}"[^>]*/>\\s*<label`));
    }
  });

  it('has words for every state the script shows and every refusal the server gives', () => {
    const shown = [...script.matchAll(/(?:show|signOut)\('([a-zA-Z]+)'\)/g)].map((m) => m[1]);
    const consent = read('functions/src/assistants/auth/consent.ts');
    const access = read('functions/src/assistants/assistant_access.ts');
    const answered = [...consent.matchAll(/error: '([a-zA-Z]+)'/g)].map((m) => m[1]);
    const refused = [...access.matchAll(/AssistantRefusal\(\s*'\w+',\s*'(\w+)'/g)]
      .map((m) => m[1])
      .filter((reason) => reason !== 'scopeNotGranted' && reason !== 'noAccess');
    const signIn = ['signInRequired', 'staleSignIn', 'kidAccount'];
    expect(refused.length).toBeGreaterThan(4);
    for (const state of [...shown, ...answered, ...refused, ...signIn]) {
      if (state === 'invalidRequest' || state === 'notFound' || state === 'invalidScopes') continue;
      expect(page, String(state)).toContain(`data-state="${String(state)}"`);
    }
  });

  it('signs in with the Firebase SDK Hosting serves itself, and reads its config from the site', () => {
    expect(built).toContain(`src="/__/firebase/${FIREBASE_WEB_SDK}/firebase-app-compat.js"`);
    expect(built).toContain(`src="/__/firebase/${FIREBASE_WEB_SDK}/firebase-auth-compat.js"`);
    expect(script).toContain("'/assets/connect-config.json'");
    const config = JSON.parse(String(site.get('assets/connect-config.json'))) as Record<
      string,
      unknown
    >;
    expect(Object.keys(config).sort()).toEqual(['apiKey', 'appId', 'authDomain', 'projectId']);
    expect(config['projectId']).toBe('nestprep-643b7');
    expect(script).toContain('Persistence.NONE');
  });

  it('has its own CSP for exactly what Firebase sign-in needs, and the rest of the site keeps its own', () => {
    const csp = (source: string): string =>
      firebase.hosting.headers
        .find((block) => block.source === source)
        ?.headers.find((header) => header.key === 'Content-Security-Policy')?.value ?? '';
    expect(csp('**')).toContain("connect-src 'self';");
    const connect = csp('/connect');
    expect(connect).toContain("script-src 'self' https://apis.google.com;");
    expect(connect).toContain(
      "connect-src 'self' https://identitytoolkit.googleapis.com https://securetoken.googleapis.com;",
    );
    const authDomain = (
      JSON.parse(String(site.get('assets/connect-config.json'))) as { authDomain: string }
    ).authDomain;
    expect(connect).toContain(`frame-src https://${authDomain};`);
    expect(connect).toContain("frame-ancestors 'none'");
  });

  it('is reached through the rewrites the assistants call, all answered with no-store', () => {
    const auth = { functionId: 'assistantAuth', region: 'europe-west1' };
    for (const source of [
      '/oauth/**',
      '/.well-known/oauth-protected-resource',
      '/.well-known/oauth-protected-resource/**',
      '/.well-known/oauth-authorization-server',
      '/.well-known/oauth-authorization-server/**',
    ]) {
      expect(firebase.hosting.rewrites).toContainEqual({ source, function: auth });
    }
    expect(firebase.hosting.rewrites).toContainEqual({
      source: '/mcp',
      function: { functionId: 'assistantMcp', region: 'europe-west1' },
    });
    const noStore = firebase.hosting.headers.find((block) => block.source.includes('/oauth/**'));
    expect(noStore?.headers).toContainEqual({ key: 'Cache-Control', value: 'no-store' });
    expect(script).toContain('`/oauth/consent/${action}`');
    for (const action of ['describe', 'households', 'decide']) {
      expect(script).toContain(`consent('${action}'`);
    }
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
