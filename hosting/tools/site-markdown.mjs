// Renders NestPrep's legal documents — `app/assets/legal/*.md` — to HTML for
// the public site. The same files are bundled into the app and drawn by its own
// renderer, so both read one deliberately small subset and nothing else:
//
//   --- front matter: title, version (an integer), updated ---
//   ## heading   ### sub heading   paragraphs (may wrap)   - bullets (one level)
//   **bold**   [text](https://… | mailto:…)   [a placeholder]
//
// A `[placeholder]` not followed by `(` is text still to be written; it is drawn
// highlighted so a draft can never pass for the finished document. Everything
// is escaped, and a link to anything but http(s) or mailto is shown as text.

const FRONT_MATTER = /^---\n([\s\S]*?)\n---\n/;
const INLINE = /\*\*(.+?)\*\*|\[([^\]\n]+)\]\(([^)\s]+)\)|\[([^\]\n]+)\]/g;
const SAFE_LINK = /^(https?:\/\/|mailto:)/i;

/** @param {string} text */
export function escapeHtml(text) {
  return text
    .replaceAll('&', '&amp;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;')
    .replaceAll('"', '&quot;')
    .replaceAll("'", '&#39;');
}

/** A heading's anchor: lower case, words joined by hyphens, nothing else. */
export function slugOf(text) {
  return text
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, '-')
    .replace(/^-|-$/g, '');
}

/**
 * The front matter and the body. A document without a title or a whole-number
 * version is refused, because the app records which version somebody accepted.
 */
export function parseDocument(source) {
  const normalised = source.replaceAll('\r\n', '\n');
  const match = FRONT_MATTER.exec(normalised);
  if (match === null) throw new Error('legal document has no front matter');
  const meta = Object.fromEntries(
    match[1].split('\n').map((line) => {
      const colon = line.indexOf(':');
      if (colon < 1) throw new Error(`front matter line is not "key: value": ${line}`);
      return [line.slice(0, colon).trim(), line.slice(colon + 1).trim()];
    }),
  );
  const version = Number(meta.version);
  if (!meta.title || !Number.isInteger(version) || version < 1) {
    throw new Error('front matter needs a title and a whole-number version');
  }
  return {
    title: meta.title,
    version,
    updated: meta.updated ?? '',
    blocks: parseBlocks(normalised.slice(match[0].length)),
  };
}

/** Headings, paragraphs and bullet lists, in order. */
export function parseBlocks(body) {
  const blocks = [];
  let paragraph = [];
  let list = null;
  const flushParagraph = () => {
    if (paragraph.length > 0) blocks.push({ kind: 'paragraph', text: paragraph.join(' ') });
    paragraph = [];
  };
  const flushList = () => {
    if (list !== null) blocks.push({ kind: 'list', items: list });
    list = null;
  };
  for (const raw of body.split('\n')) {
    const line = raw.trim();
    const heading = /^(#{2,3}) (.+)$/.exec(line);
    if (line === '') {
      flushParagraph();
      flushList();
    } else if (heading !== null) {
      flushParagraph();
      flushList();
      blocks.push({ kind: heading[1].length === 2 ? 'heading' : 'subheading', text: heading[2] });
    } else if (line.startsWith('- ')) {
      flushParagraph();
      list ??= [];
      list.push(line.slice(2));
    } else if (/^(#|\d+\. |\* |> |\|)/.test(line)) {
      throw new Error(`outside the legal markdown subset: ${line}`);
    } else {
      flushList();
      paragraph.push(line);
    }
  }
  flushParagraph();
  flushList();
  return blocks;
}

/** One line of text with its bold, links and placeholders. */
export function renderInline(text) {
  let html = '';
  let last = 0;
  for (const match of text.matchAll(INLINE)) {
    html += escapeHtml(text.slice(last, match.index));
    const [whole, bold, linkText, href, placeholder] = match;
    if (bold !== undefined) {
      html += `<strong>${renderInline(bold)}</strong>`;
    } else if (linkText !== undefined) {
      html += SAFE_LINK.test(href)
        ? `<a href="${escapeHtml(href)}">${escapeHtml(linkText)}</a>`
        : escapeHtml(whole);
    } else {
      html += `<mark class="placeholder">[${escapeHtml(placeholder)}]</mark>`;
    }
    last = match.index + whole.length;
  }
  return html + escapeHtml(text.slice(last));
}

/** The body as HTML, each `##` heading given an anchor the contents link to. */
export function renderBlocks(blocks) {
  return blocks
    .map((block) => {
      switch (block.kind) {
        case 'heading':
          return `<h2 id="${slugOf(block.text)}">${renderInline(block.text)}</h2>`;
        case 'subheading':
          return `<h3>${renderInline(block.text)}</h3>`;
        case 'list':
          return `<ul>\n${block.items.map((item) => `  <li>${renderInline(item)}</li>`).join('\n')}\n</ul>`;
        default:
          return `<p>${renderInline(block.text)}</p>`;
      }
    })
    .join('\n');
}

/** The `##` headings, for a document's table of contents. */
export function headingsOf(blocks) {
  return blocks
    .filter((block) => block.kind === 'heading')
    .map((block) => ({ id: slugOf(block.text), text: block.text }));
}
