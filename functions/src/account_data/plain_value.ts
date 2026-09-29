import { DocumentReference, GeoPoint, Timestamp } from 'firebase-admin/firestore';

/** A value JSON can hold without losing what it meant. */
export type PlainValue =
  string | number | boolean | null | readonly PlainValue[] | { readonly [key: string]: PlainValue };

/**
 * A stored Firestore value as a person can read it in an export (accounts
 * ADR-0006): instants as ISO-8601 in UTC (`ENG-21`), positions as latitude and
 * longitude, references as their path. Nothing is dropped silently — a value
 * of a kind this does not know becomes its type name, so the gap is visible.
 */
export function plainValue(value: unknown): PlainValue {
  if (value === null || value === undefined) return null;
  if (typeof value === 'string' || typeof value === 'boolean') return value;
  if (typeof value === 'number') return Number.isFinite(value) ? value : String(value);
  if (value instanceof Timestamp) return value.toDate().toISOString();
  if (value instanceof Date) return value.toISOString();
  if (value instanceof GeoPoint) return { latitude: value.latitude, longitude: value.longitude };
  if (value instanceof DocumentReference) return value.path;
  if (Array.isArray(value)) return value.map(plainValue);
  if (typeof value === 'object') {
    const entries = Object.entries(value).sort(([a], [b]) => a.localeCompare(b));
    return Object.fromEntries(entries.map(([key, inner]) => [key, plainValue(inner)]));
  }
  return `[${typeof value}]`;
}

/** A document's fields, plus its id, as plain values; null when it does not exist. */
export function plainDocument(
  id: string,
  data: Record<string, unknown> | undefined,
): PlainValue | null {
  if (data === undefined) return null;
  const fields = plainValue(data);
  return isPlainRecord(fields) ? { id, ...fields } : { id };
}

/** A plain value that is a record of fields rather than a list or a scalar. */
export function isPlainRecord(
  value: PlainValue | null,
): value is { readonly [key: string]: PlainValue } {
  return typeof value === 'object' && value !== null && !Array.isArray(value);
}
