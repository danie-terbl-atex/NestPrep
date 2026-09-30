/**
 * Small, obviously-fake files for the demo's documents: a one-page PDF of
 * text and a flat-colour PNG. Made here rather than committed, so there is no
 * binary to keep and nothing in them that could be a real person's (ENG-22).
 * The JPEGs home care and the nanny hub need are committed beside this file,
 * because Node has no JPEG encoder and those paths take nothing else.
 */
import { deflateSync } from 'node:zlib';

/** Escapes the three characters a PDF string cannot hold as they are. */
function pdfText(text) {
  return text.replace(/[\\()]/g, (character) => `\\${character}`).replace(/[^\x20-\x7e]/g, '-');
}

/** An A4 page with [title] large and [lines] below it, stamped DEMO. */
export function pdfDocument(title, lines) {
  const body = [
    'BT /F1 22 Tf 56 770 Td',
    `(${pdfText(title)}) Tj`,
    '/F1 11 Tf 0 -36 Td 15 TL',
    ...lines.map((line) => `(${pdfText(line)}) '`),
    'ET',
    'BT /F1 60 Tf 0.9 g 150 300 Td (DEMO ONLY) Tj ET',
  ].join('\n');
  const objects = [
    '<< /Type /Catalog /Pages 2 0 R >>',
    '<< /Type /Pages /Kids [3 0 R] /Count 1 >>',
    '<< /Type /Page /Parent 2 0 R /MediaBox [0 0 595 842] /Resources << /Font << /F1 4 0 R >> >> /Contents 5 0 R >>',
    '<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica >>',
    `<< /Length ${String(Buffer.byteLength(body))} >>\nstream\n${body}\nendstream`,
  ];
  let out = '%PDF-1.4\n';
  const offsets = [];
  objects.forEach((object, index) => {
    offsets.push(Buffer.byteLength(out));
    out += `${String(index + 1)} 0 obj\n${object}\nendobj\n`;
  });
  const xref = Buffer.byteLength(out);
  out += `xref\n0 ${String(objects.length + 1)}\n0000000000 65535 f \n`;
  for (const offset of offsets) out += `${String(offset).padStart(10, '0')} 00000 n \n`;
  out += `trailer\n<< /Size ${String(objects.length + 1)} /Root 1 0 R >>\nstartxref\n${String(xref)}\n%%EOF\n`;
  return Buffer.from(out, 'latin1');
}

const CRC_TABLE = Array.from({ length: 256 }, (_, n) => {
  let c = n;
  for (let k = 0; k < 8; k += 1) c = c & 1 ? 0xedb88320 ^ (c >>> 1) : c >>> 1;
  return c >>> 0;
});

function crc32(buffer) {
  let c = 0xffffffff;
  for (const byte of buffer) c = CRC_TABLE[(c ^ byte) & 0xff] ^ (c >>> 8);
  return (c ^ 0xffffffff) >>> 0;
}

function chunk(type, data) {
  const length = Buffer.alloc(4);
  length.writeUInt32BE(data.length);
  const typed = Buffer.concat([Buffer.from(type, 'ascii'), data]);
  const crc = Buffer.alloc(4);
  crc.writeUInt32BE(crc32(typed));
  return Buffer.concat([length, typed, crc]);
}

/**
 * A [width]×[height] RGB PNG whose every pixel is `paint(x, y)` → [r, g, b].
 * Enough for a letterhead band, a card, a tiled wall.
 */
export function pngPicture(width, height, paint) {
  const raw = Buffer.alloc((width * 3 + 1) * height);
  for (let y = 0; y < height; y += 1) {
    const row = y * (width * 3 + 1);
    raw[row] = 0;
    for (let x = 0; x < width; x += 1) {
      const [r, g, b] = paint(x, y);
      raw[row + 1 + x * 3] = r;
      raw[row + 2 + x * 3] = g;
      raw[row + 3 + x * 3] = b;
    }
  }
  const header = Buffer.alloc(13);
  header.writeUInt32BE(width, 0);
  header.writeUInt32BE(height, 4);
  header[8] = 8;
  header[9] = 2;
  return Buffer.concat([
    Buffer.from([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a]),
    chunk('IHDR', header),
    chunk('IDAT', deflateSync(raw)),
    chunk('IEND', Buffer.alloc(0)),
  ]);
}

/** A card-like picture: a coloured band on top, grey text lines under it. */
export function cardPicture(width, height, band) {
  return pngPicture(width, height, (x, y) => {
    if (y < height * 0.22) return band;
    const line = Math.floor((y - height * 0.3) / (height * 0.08));
    const inLine = line >= 0 && line < 7 && (y - height * 0.3) % (height * 0.08) < height * 0.03;
    const lineEnd = width * (0.85 - (line % 3) * 0.15);
    if (inLine && x > width * 0.08 && x < lineEnd) return [200, 200, 205];
    return [252, 251, 248];
  });
}
