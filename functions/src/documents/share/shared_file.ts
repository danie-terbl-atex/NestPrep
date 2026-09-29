/**
 * How a shared document leaves as a file (documents ADR-0006): only the five
 * types a household keeps (the same list as `storage.rules`), inline rather
 * than as a download, and named after the document without anything a header
 * could be broken by.
 */
const KEPT_TYPES: Readonly<Record<string, string>> = {
  'application/pdf': 'pdf',
  'image/jpeg': 'jpg',
  'image/png': 'png',
  'image/heic': 'heic',
  'image/webp': 'webp',
};

export function isKeptContentType(contentType: string): boolean {
  return Object.hasOwn(KEPT_TYPES, contentType);
}

/**
 * `inline; filename="…"` with an ASCII fallback and the real name in
 * RFC 5987 form, so "Émile's passport" survives and a quote or a newline in
 * a name cannot end the header early.
 */
export function contentDispositionFor(documentName: string, contentType: string): string {
  const extension = KEPT_TYPES[contentType] ?? 'bin';
  const base = documentName.trim() === '' ? 'document' : documentName.trim();
  const ascii = base.replace(/[^A-Za-z0-9 ._-]/g, '_').slice(0, 80);
  const encoded = encodeURIComponent(`${base}.${extension}`);
  return `inline; filename="${ascii}.${extension}"; filename*=UTF-8''${encoded}`;
}
