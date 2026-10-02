/**
 * The colours of the shared-link page, copied from the app's tokens
 * (`app/lib/design/tokens/nest_colors.dart`) because this page is served by a
 * Function and cannot import them. Each entry names the token it copies, and
 * `share_page_theme.test.ts` reads the Dart file and fails when a value here
 * no longer matches the token of that name — the lesson on contracts between
 * two languages (documents ADR-0006, design-system ADR-0008).
 *
 * Ink acts, Guava selects as a fill carrying Ink, Oat is the page.
 */
export const SHARE_TOKEN_NAMES = [
  'canvas',
  'surface',
  'outline',
  'ink',
  'inkSecondary',
  'accent',
  'onAccent',
  'accentSoft',
  'accentInk',
  'danger',
  'dangerSoft',
  'tileButter',
] as const;

export type SharePalette = Readonly<Record<(typeof SHARE_TOKEN_NAMES)[number], string>>;

export const LIGHT: SharePalette = {
  canvas: '#FFF8ED',
  surface: '#F5E9D7',
  outline: '#D6C2A8',
  ink: '#35252E',
  inkSecondary: '#6E5F65',
  accent: '#35252E',
  onAccent: '#FFF8ED',
  accentSoft: '#E4EADC',
  accentInk: '#465C48',
  danger: '#B4232F',
  dangerSoft: '#FBE1DE',
  tileButter: '#F3D886',
};

export const DARK: SharePalette = {
  canvas: '#211A20',
  surface: '#2E252C',
  outline: '#54444D',
  ink: '#FFF8ED',
  inkSecondary: '#CDBFC4',
  accent: '#FFF8ED',
  onAccent: '#35252E',
  accentSoft: '#2F3A30',
  accentInk: '#B3CDB4',
  danger: '#FF9B9B',
  dangerSoft: '#4A2529',
  tileButter: '#4D4227',
};

function variables(palette: SharePalette): string {
  return SHARE_TOKEN_NAMES.map((name) => `--${name}:${palette[name]};`).join('');
}

/**
 * The whole stylesheet, inline: the page loads nothing but itself, the mark
 * and the document. Mobile first — one column, 44 px targets, text that
 * scales with the browser's setting — in light and dark.
 */
export function sharePageStyles(): string {
  return `
:root{${variables(LIGHT)}color-scheme:light dark}
@media (prefers-color-scheme:dark){:root{${variables(DARK)}}}
*{box-sizing:border-box}
body{margin:0;background:var(--canvas);color:var(--ink);font:1rem/1.5 "DM Sans",system-ui,-apple-system,"Segoe UI",Roboto,sans-serif;-webkit-text-size-adjust:100%}
main{max-width:34rem;margin:0 auto;padding:1.5rem 1rem 3rem}
header{display:flex;align-items:center;gap:.75rem;margin-bottom:1.5rem}
header img{width:2.5rem;height:auto}
header span{font:600 1.5rem/1 Fraunces,Georgia,"Times New Roman",serif;letter-spacing:-.04em;color:var(--ink)}
.card{background:var(--surface);border:1px solid var(--outline);border-radius:1.5rem;padding:1.25rem}
h1{font:600 1.6rem/1.15 Fraunces,Georgia,"Times New Roman",serif;margin:0 0 .5rem;overflow-wrap:anywhere}
p{margin:0 0 1rem;color:var(--inkSecondary)}
.tag{display:inline-block;background:var(--accentSoft);color:var(--accentInk);border-radius:999px;padding:.25rem .75rem;font-weight:600;font-size:.875rem;margin-bottom:1rem}
.document{display:block;width:100%;height:auto;border-radius:1rem;border:1px solid var(--outline);background:var(--tileButter)}
.button{display:flex;align-items:center;justify-content:center;min-height:3rem;width:100%;border:0;border-radius:999px;background:var(--accent);color:var(--onAccent);font-family:inherit;font-weight:700;font-size:1rem;line-height:1.2;text-decoration:none;padding:.75rem 1.5rem;cursor:pointer}
label{display:block;font-weight:600;margin-bottom:.5rem;color:var(--ink)}
input{display:block;width:100%;min-height:3rem;font-family:inherit;font-weight:600;font-size:1.5rem;line-height:1;letter-spacing:.5rem;text-align:center;border:2px solid var(--outline);border-radius:1rem;background:var(--canvas);color:var(--ink);margin-bottom:1rem;padding:.5rem}
input:focus{outline:3px solid var(--accent);outline-offset:2px}
.problem{background:var(--dangerSoft);color:var(--danger);border-radius:1rem;padding:.75rem 1rem;font-weight:600}
.note{margin-top:.75rem}
.card>:last-child{margin-bottom:0}
footer{margin-top:1.5rem;font-size:.875rem;color:var(--inkSecondary)}
`.trim();
}
