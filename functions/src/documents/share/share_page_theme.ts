/**
 * The colours of the shared-link page, copied from the app's tokens
 * (`app/lib/design/tokens/nest_colors.dart`) because this page is served by a
 * Function and cannot import them. Each entry names the token it copies, and
 * `share_page_theme.test.ts` reads the Dart file and fails when a value here
 * no longer matches the token of that name — the lesson on contracts between
 * two languages (documents ADR-0006, design-system ADR-0003).
 *
 * Green acts, teal selects, cream is the page; tomato is never words.
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
  'secondary',
  'danger',
  'dangerSoft',
  'tilePeach',
] as const;

export type SharePalette = Readonly<Record<(typeof SHARE_TOKEN_NAMES)[number], string>>;

export const LIGHT: SharePalette = {
  canvas: '#F4EDDF',
  surface: '#FFFFFF',
  outline: '#E3D8C4',
  ink: '#1C2920',
  inkSecondary: '#4F5A52',
  accent: '#32533C',
  onAccent: '#FFFFFF',
  accentSoft: '#E2EEDF',
  accentInk: '#2A4A33',
  secondary: '#2F6B70',
  danger: '#B8283A',
  dangerSoft: '#FBE4E6',
  tilePeach: '#F7E8C8',
};

export const DARK: SharePalette = {
  canvas: '#0F1411',
  surface: '#212A23',
  outline: '#3A443C',
  ink: '#F5F1E6',
  inkSecondary: '#C5C6B8',
  accent: '#9CCFA7',
  onAccent: '#0F2317',
  accentSoft: '#253B2C',
  accentInk: '#BCE2C4',
  secondary: '#7DC4C9',
  danger: '#FF8088',
  dangerSoft: '#3D2024',
  tilePeach: '#3A301C',
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
body{margin:0;background:var(--canvas);color:var(--ink);font:1rem/1.5 "Plus Jakarta Sans",system-ui,-apple-system,"Segoe UI",Roboto,sans-serif;-webkit-text-size-adjust:100%}
main{max-width:34rem;margin:0 auto;padding:1.5rem 1rem 3rem}
header{display:flex;align-items:center;gap:.75rem;margin-bottom:1.5rem}
header img{width:3rem;height:auto}
header span{font:800 1.4rem/1 Nunito,ui-rounded,system-ui,sans-serif;color:var(--accent)}
.card{background:var(--surface);border:1px solid var(--outline);border-radius:1.5rem;padding:1.25rem}
h1{font:800 1.5rem/1.25 Nunito,ui-rounded,system-ui,sans-serif;margin:0 0 .5rem;overflow-wrap:anywhere}
p{margin:0 0 1rem;color:var(--inkSecondary)}
.tag{display:inline-block;background:var(--accentSoft);color:var(--accentInk);border-radius:999px;padding:.25rem .75rem;font-weight:600;font-size:.875rem;margin-bottom:1rem}
.document{display:block;width:100%;height:auto;border-radius:1rem;border:1px solid var(--outline);background:var(--tilePeach)}
.button{display:flex;align-items:center;justify-content:center;min-height:3rem;width:100%;border:0;border-radius:999px;background:var(--accent);color:var(--onAccent);font-family:inherit;font-weight:700;font-size:1rem;line-height:1.2;text-decoration:none;padding:.75rem 1.5rem;cursor:pointer}
label{display:block;font-weight:600;margin-bottom:.5rem;color:var(--ink)}
input{display:block;width:100%;min-height:3rem;font-family:inherit;font-weight:600;font-size:1.5rem;line-height:1;letter-spacing:.5rem;text-align:center;border:2px solid var(--outline);border-radius:1rem;background:var(--canvas);color:var(--ink);margin-bottom:1rem;padding:.5rem}
input:focus{outline:3px solid var(--secondary);outline-offset:2px}
.problem{background:var(--dangerSoft);color:var(--danger);border-radius:1rem;padding:.75rem 1rem;font-weight:600}
.note{margin-top:.75rem}
.card>:last-child{margin-bottom:0}
footer{margin-top:1.5rem;font-size:.875rem;color:var(--inkSecondary)}
`.trim();
}
