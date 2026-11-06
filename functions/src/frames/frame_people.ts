import { GeoPoint, Timestamp } from 'firebase-admin/firestore';
import { z } from 'zod';

/**
 * Where everyone is, on a frame (C-0023 rev 15): each member of the day by
 * first name, with a position only while they share one. Nothing here is
 * derived from the clock but whether a share has ended, so the panel is the
 * same between two calls when nobody wrote, and the frame skips the redraw.
 */

export const FRAME_LOCATION_LIMIT = 50;
export const FRAME_PLACE_LIMIT = 30;

const LIVE_WITHIN_MS = 2 * 60_000;
const LIVE_WITHIN_ALWAYS_MS = 75 * 60_000;
const EARTH_RADIUS_METRES = 6_371_000;

export const frameStoredLocation = z
  .object({
    point: z.instanceof(GeoPoint),
    accuracyMetres: z.number().int().min(0),
    reportedAt: z.instanceof(Timestamp).nullable().catch(null),
    sharingUntil: z.instanceof(Timestamp),
    mode: z.enum(['window', 'continuous']).catch('window'),
  })
  .transform((stored) => ({
    lat: stored.point.latitude,
    lng: stored.point.longitude,
    accuracyMetres: stored.accuracyMetres,
    reportedAt: stored.reportedAt?.toMillis() ?? null,
    sharingUntil: stored.sharingUntil.toMillis(),
    continuous: stored.mode === 'continuous',
  }));

export const frameStoredPlace = z
  .object({
    name: z.string().min(1),
    centre: z.instanceof(GeoPoint),
    radiusMetres: z.number().positive(),
    icon: z.string().catch(''),
  })
  .transform((stored) => ({
    name: stored.name,
    lat: stored.centre.latitude,
    lng: stored.centre.longitude,
    radiusMetres: Math.round(stored.radiusMetres),
    home: stored.icon === 'home',
  }));

export type FrameLocationRecord = z.infer<typeof frameStoredLocation> & {
  readonly memberId: string;
};
export type FramePlaceRecord = z.infer<typeof frameStoredPlace> & { readonly id: string };

export interface FramePeopleSources {
  readonly locations: readonly FrameLocationRecord[];
  readonly places: readonly FramePlaceRecord[];
  readonly now: number;
}

export interface FrameNamedMember {
  readonly id: string;
  readonly name: string;
}

export type FramePerson =
  | { readonly name: string }
  | {
      readonly name: string;
      readonly lat: number;
      readonly lng: number;
      readonly accuracyMetres: number;
      readonly reportedAt: number;
      readonly liveUntil: number;
      readonly place?: string;
    };

export interface FramePeople {
  readonly home?: { readonly lat: number; readonly lng: number; readonly radiusMetres: number };
  readonly people: FramePerson[];
}

export function peoplePanel(
  members: readonly FrameNamedMember[],
  sources: FramePeopleSources,
): FramePeople {
  const places = [...sources.places].sort(smallestFirst);
  const home = places.find((place) => place.home);
  const located = new Map(sources.locations.map((location) => [location.memberId, location]));
  return {
    ...(home === undefined
      ? {}
      : {
          home: { lat: rounded(home.lat), lng: rounded(home.lng), radiusMetres: home.radiusMetres },
        }),
    people: members.map(({ id, name }) => personOf(name, located.get(id), places, sources.now)),
  };
}

function personOf(
  name: string,
  location: FrameLocationRecord | undefined,
  places: readonly FramePlaceRecord[],
  now: number,
): FramePerson {
  if (location === undefined || location.sharingUntil <= now || location.reportedAt === null) {
    return { name };
  }
  const place = places.find(
    (candidate) =>
      metresBetween(candidate.lat, candidate.lng, location.lat, location.lng) <=
      candidate.radiusMetres,
  );
  return {
    name,
    lat: rounded(location.lat),
    lng: rounded(location.lng),
    accuracyMetres: location.accuracyMetres,
    reportedAt: location.reportedAt,
    liveUntil: location.reportedAt + (location.continuous ? LIVE_WITHIN_ALWAYS_MS : LIVE_WITHIN_MS),
    ...(place === undefined ? {} : { place: place.name }),
  };
}

function smallestFirst(a: FramePlaceRecord, b: FramePlaceRecord): number {
  return a.radiusMetres - b.radiusMetres || (a.id < b.id ? -1 : a.id > b.id ? 1 : 0);
}

function rounded(degrees: number): number {
  return Math.round(degrees * 1e5) / 1e5;
}

export function metresBetween(aLat: number, aLng: number, bLat: number, bLng: number): number {
  const radians = Math.PI / 180;
  const dLat = (bLat - aLat) * radians;
  const dLng = (bLng - aLng) * radians;
  const h =
    Math.sin(dLat / 2) ** 2 +
    Math.cos(aLat * radians) * Math.cos(bLat * radians) * Math.sin(dLng / 2) ** 2;
  return EARTH_RADIUS_METRES * 2 * Math.atan2(Math.sqrt(h), Math.sqrt(1 - h));
}
