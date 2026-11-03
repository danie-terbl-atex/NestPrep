import { describe, expect, it } from 'vitest';

import { FRAME_LINK_MAX, frameLink } from '../../../src/frames/frame_links';

const long = (length: number): string => {
  const head = 'https://example.com/';
  return head + 'a'.repeat(length - head.length);
};

describe('a link a frame opens', () => {
  it.each([
    [
      'https://www.bbcgoodfood.com/recipes/chicken-curry',
      'https://www.bbcgoodfood.com/recipes/chicken-curry',
    ],
    [
      'https://www.allrecipes.com/recipe/2/pancakes/?servings=4&units=metric',
      'https://www.allrecipes.com/recipe/2/pancakes/?servings=4&units=metric',
    ],
    ['https://example.com/recipe#method', 'https://example.com/recipe#method'],
    ['http://example.com/recipe?a=1#step-2', 'http://example.com/recipe?a=1#step-2'],
    ['HTTPS://WWW.Example.COM/Recipe', 'https://www.example.com/Recipe'],
    ['https://münchen-rezepte.de/käse', 'https://xn--mnchen-rezepte-gsb.de/k%C3%A4se'],
    ['https://xn--mnchen-3ya.de/', 'https://xn--mnchen-3ya.de/'],
    ['https://example.com:443/a', 'https://example.com/a'],
    ['http://example.com:80/', 'http://example.com/'],
    ['  https://example.com/recipe  ', 'https://example.com/recipe'],
    ['https://example.com/a b', 'https://example.com/a%20b'],
    ['https://example.com.', 'https://example.com./'],
    ['https://recipes.co.za/x', 'https://recipes.co.za/x'],
    [long(FRAME_LINK_MAX), long(FRAME_LINK_MAX)],
  ])('opens %s', (raw, href) => {
    expect(frameLink(raw)).toBe(href);
  });

  it.each([
    ['not a url', 'recipe'],
    ['not a url', ''],
    ['not a url', 'https://'],
    ['not a url', 'https://foo.123/'],
    ['too long', long(FRAME_LINK_MAX + 1)],
    ['not http', 'ftp://example.com/recipe'],
    ['not http', 'file:///etc/passwd'],
    ['not http', 'javascript:alert(1)'],
    ['not http', 'data:text/html,<h1>hi</h1>'],
    ['not http', 'intent://example.com#Intent;end'],
    ['not http', 'chrome://settings'],
    ['a username', 'https://user@example.com/'],
    ['a password', 'https://:secret@example.com/'],
    ['both', 'https://user:secret@example.com/'],
    ['a port', 'https://example.com:8443/'],
    ['a port', 'http://example.com:8080/'],
    ['a port', 'http://example.com:443/'],
    ['an IPv4 literal', 'http://192.168.1.1/'],
    ['an IPv4 literal', 'http://8.8.8.8/'],
    ['an IPv4 literal in another spelling', 'http://0x7f.1/'],
    ['an IPv4 literal in another spelling', 'http://3232235777/'],
    ['an IPv6 literal', 'http://[::1]/'],
    ['an IPv6 literal', 'http://[fe80::1]/admin'],
    ['no dot', 'http://router/'],
    ['no dot', 'http://nas./'],
    ['localhost', 'http://localhost/'],
    ['localhost', 'http://LOCALHOST./'],
    ['.localhost', 'http://app.localhost/'],
    ['.local', 'http://nas.local/'],
    ['.local', 'http://nas.local./'],
    ['.lan', 'http://router.lan/'],
    ['.home', 'http://printer.home/'],
    ['.internal', 'http://wiki.internal/'],
    ['.intranet', 'http://hr.intranet/'],
    ['.corp', 'http://mail.corp/'],
    ['.home.arpa', 'http://router.home.arpa/'],
    ['.arpa', 'http://1.168.192.in-addr.arpa/'],
  ])('refuses %s: %s', (_why, raw) => {
    expect(frameLink(raw)).toBeNull();
  });

  it('keeps hosts that merely contain a private word', () => {
    expect(frameLink('https://local.example.com/')).toBe('https://local.example.com/');
    expect(frameLink('https://homemade.co/')).toBe('https://homemade.co/');
    expect(frameLink('https://thelocal.se/')).toBe('https://thelocal.se/');
  });
});
