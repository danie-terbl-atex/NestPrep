// Types for `site-markdown.mjs`, so the Functions test suite can import it
// under `strict` without an `any` (ENG-09).

export type LegalBlock =
  | { kind: 'heading' | 'subheading' | 'paragraph'; text: string }
  | { kind: 'list'; items: string[] };

export interface LegalDocument {
  title: string;
  version: number;
  updated: string;
  blocks: LegalBlock[];
}

export function escapeHtml(text: string): string;
export function slugOf(text: string): string;
export function parseDocument(source: string): LegalDocument;
export function parseBlocks(body: string): LegalBlock[];
export function renderInline(text: string): string;
export function renderBlocks(blocks: readonly LegalBlock[]): string;
export function headingsOf(blocks: readonly LegalBlock[]): { id: string; text: string }[];
