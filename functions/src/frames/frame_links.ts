export const FRAME_LINK_MAX = 2048;

const PRIVATE_SUFFIXES = [
  '.localhost',
  '.local',
  '.lan',
  '.home',
  '.internal',
  '.intranet',
  '.corp',
  '.home.arpa',
  '.arpa',
] as const;

const IPV4 = /^\d{1,3}(\.\d{1,3}){3}$/;

export function frameLink(raw: string): string | null {
  if (!URL.canParse(raw)) return null;
  const url = new URL(raw);
  if (url.href.length > FRAME_LINK_MAX) return null;
  if (url.protocol !== 'http:' && url.protocol !== 'https:') return null;
  if (url.username !== '' || url.password !== '' || url.port !== '') return null;
  return isPublicHost(url.hostname) ? url.href : null;
}

// The frame sits on the family's home network, so routers, NAS boxes and other LAN pages stay off the wall.
function isPublicHost(hostname: string): boolean {
  const host = hostname.endsWith('.') ? hostname.slice(0, -1) : hostname;
  if (host.startsWith('[') || IPV4.test(host) || !host.includes('.')) return false;
  if (host === 'localhost') return false;
  return !PRIVATE_SUFFIXES.some((suffix) => host.endsWith(suffix));
}
