import { refuseListScan } from './errors';
import { MAX_LIST_PHOTO_BYTES, type ListPhotoType } from './schemas';

const SIGNATURES: Record<ListPhotoType, readonly number[]> = {
  'image/jpeg': [0xff, 0xd8, 0xff],
  'image/png': [0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a],
};

const BASE64 = /^[A-Za-z0-9+/]+={0,2}$/;

/**
 * The photo's base64, checked before a token is spent: valid, no larger than
 * a photo needs to be, and really the image it claims to be.
 */
export function checkedListPhoto(mimeType: ListPhotoType, data: string): string {
  if (!BASE64.test(data) || data.length % 4 !== 0) throw refuseListScan('listPhotoNotSupported');
  const bytes = Buffer.from(data, 'base64');
  if (bytes.length > MAX_LIST_PHOTO_BYTES) throw refuseListScan('listPhotoTooLarge');
  const matches = SIGNATURES[mimeType].every((byte, index) => bytes[index] === byte);
  if (!matches) throw refuseListScan('listPhotoNotSupported');
  return data;
}
