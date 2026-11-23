import { refuseListScan } from './errors';
import { MAX_LIST_PHOTO_BYTES, type ListPhotoType } from './schemas';

const SIGNATURES: Record<ListPhotoType, readonly number[]> = {
  'image/jpeg': [0xff, 0xd8, 0xff],
  'image/png': [0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a],
};

const BASE64 = /^[A-Za-z0-9+/]+={0,2}$/;

const START_OF_SCAN = 0xda;
const FIRST_METADATA = 0xe1;
const LAST_METADATA = 0xef;

/**
 * The photo's base64, checked before a token is spent: valid, no larger than
 * a photo needs to be, and really the image it claims to be. A JPEG leaves
 * without its metadata (recipes ADR-0011).
 */
export function checkedListPhoto(mimeType: ListPhotoType, data: string): string {
  if (!BASE64.test(data) || data.length % 4 !== 0) throw refuseListScan('listPhotoNotSupported');
  const bytes = Buffer.from(data, 'base64');
  if (bytes.length > MAX_LIST_PHOTO_BYTES) throw refuseListScan('listPhotoTooLarge');
  const matches = SIGNATURES[mimeType].every((byte, index) => bytes[index] === byte);
  if (!matches) throw refuseListScan('listPhotoNotSupported');
  if (mimeType !== 'image/jpeg') return data;
  const stripped = withoutMetadata(bytes);
  return stripped === bytes ? data : stripped.toString('base64');
}

/**
 * The JPEG without its APP1–APP15 segments (EXIF, ICC, MPF, XMP), or the same
 * buffer when it has none or its segments cannot be followed. `image` 4.10.1
 * writes an ICC profile without its sequence bytes, and Vertex refuses the
 * whole file as corrupt.
 */
export function withoutMetadata(jpeg: Buffer): Buffer {
  const kept: Buffer[] = [jpeg.subarray(0, 2)];
  let at = 2;
  let dropped = false;
  while (at + 4 <= jpeg.length) {
    if (jpeg[at] !== 0xff) return jpeg;
    const marker = jpeg[at + 1] ?? 0;
    if (marker === 0xff) {
      at += 1;
      continue;
    }
    if (marker === START_OF_SCAN) {
      kept.push(jpeg.subarray(at));
      return dropped ? Buffer.concat(kept) : jpeg;
    }
    const end = at + 2 + jpeg.readUInt16BE(at + 2);
    if (end > jpeg.length) return jpeg;
    if (marker >= FIRST_METADATA && marker <= LAST_METADATA) {
      dropped = true;
    } else {
      kept.push(jpeg.subarray(at, end));
    }
    at = end;
  }
  return jpeg;
}
