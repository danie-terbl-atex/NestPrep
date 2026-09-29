// Types for `site-pages.mjs`, so the Functions test suite can import it under
// `strict` without an `any` (ENG-09).

export const COPIED_ASSETS: readonly (readonly [string, string])[];
export const LEGAL_DOCUMENTS: readonly {
  source: string;
  output: string;
  nav: string;
  description: string;
}[];
export function buildSite(repoRoot: string): Map<string, string | Buffer>;
