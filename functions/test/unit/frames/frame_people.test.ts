import { GeoPoint, Timestamp } from 'firebase-admin/firestore';
import { describe, expect, it } from 'vitest';

import { parsed } from '../../../src/frames/frame_documents';
import {
  type FrameLocationRecord,
  type FramePlaceRecord,
  frameStoredLocation,
  frameStoredPlace,
  metresBetween,
  peoplePanel,
} from '../../../src/frames/frame_people';

const NOW = 1_762_400_000_000;
const MINUTE = 60_000;
const MEMBERS = [
  { id: 'm-leo', name: 'Leo' },
  { id: 'm-mia', name: 'Mia' },
  { id: 'm-sam', name: 'Sam' },
];
const SCHOOL = { lat: -33.96221, lng: 18.47123 };

function location(memberId: string, more: Partial<FrameLocationRecord> = {}): FrameLocationRecord {
  return {
    memberId,
    lat: SCHOOL.lat,
    lng: SCHOOL.lng,
    accuracyMetres: 12,
    reportedAt: NOW - MINUTE,
    sharingUntil: NOW + 60 * MINUTE,
    continuous: false,
    ...more,
  };
}

function place(id: string, name: string, more: Partial<FramePlaceRecord> = {}): FramePlaceRecord {
  return { id, name, lat: SCHOOL.lat, lng: SCHOOL.lng, radiusMetres: 150, home: false, ...more };
}

describe('where everyone is (C-0023 rev 15)', () => {
  it('lists every member in the day’s order, a position only for who is sharing', () => {
    expect(peoplePanel(MEMBERS, { locations: [location('m-sam')], places: [], now: NOW })).toEqual({
      people: [
        { name: 'Leo' },
        { name: 'Mia' },
        {
          name: 'Sam',
          lat: -33.96221,
          lng: 18.47123,
          accuracyMetres: 12,
          reportedAt: NOW - MINUTE,
          liveUntil: NOW + MINUTE,
        },
      ],
    });
  });

  it('a share that has ended, or a position not yet stamped, is the name alone', () => {
    const { people } = peoplePanel(MEMBERS, {
      locations: [
        location('m-leo', { sharingUntil: NOW }),
        location('m-mia', { sharingUntil: NOW - 1 }),
        location('m-sam', { reportedAt: null }),
      ],
      places: [],
      now: NOW,
    });
    expect(people).toEqual([{ name: 'Leo' }, { name: 'Mia' }, { name: 'Sam' }]);
  });

  it('stays live two minutes after a window report and 75 after an always-on one', () => {
    const reportedAt = NOW - 30 * MINUTE;
    const { people } = peoplePanel(MEMBERS, {
      locations: [
        location('m-leo', { reportedAt }),
        location('m-mia', { reportedAt, continuous: true }),
      ],
      places: [],
      now: NOW,
    });
    expect(people[0]).toMatchObject({ reportedAt, liveUntil: reportedAt + 2 * MINUTE });
    expect(people[1]).toMatchObject({ reportedAt, liveUntil: reportedAt + 75 * MINUTE });
  });

  it('ignores a position for somebody who is not a member of the day', () => {
    const { people } = peoplePanel(MEMBERS, {
      locations: [location('m-gone')],
      places: [],
      now: NOW,
    });
    expect(people).toEqual([{ name: 'Leo' }, { name: 'Mia' }, { name: 'Sam' }]);
  });

  it('rounds to five places and leaves nothing else derived from the clock', () => {
    const sources = {
      locations: [location('m-sam', { lat: -33.962214999, lng: 18.471235001 })],
      places: [],
      now: NOW,
    };
    const first = peoplePanel(MEMBERS, sources);
    expect(first.people[2]).toMatchObject({ lat: -33.96221, lng: 18.47124 });
    expect(peoplePanel(MEMBERS, { ...sources, now: NOW + 30 * MINUTE })).toEqual(first);
  });

  it('names the smallest place the position is inside, and none when outside every place', () => {
    const near = { lat: SCHOOL.lat + 0.0009, lng: SCHOOL.lng };
    const places = [
      place('p-suburb', 'Rondebosch', { radiusMetres: 500 }),
      place('p-school', 'School', { radiusMetres: 75 }),
      place('p-field', 'Sports field', { radiusMetres: 150 }),
    ];
    const { people } = peoplePanel(MEMBERS, {
      locations: [
        location('m-leo'),
        location('m-mia', near),
        location('m-sam', { lat: SCHOOL.lat + 0.01, lng: SCHOOL.lng }),
      ],
      places,
      now: NOW,
    });
    expect(people[0]).toMatchObject({ place: 'School' });
    expect(people[1]).toMatchObject({ place: 'Sports field' });
    expect(people[2]).not.toHaveProperty('place');
  });

  it('two places of one size: the first by id', () => {
    const { people } = peoplePanel(MEMBERS, {
      locations: [location('m-leo')],
      places: [place('p-b', 'Gran’s'), place('p-a', 'Aftercare')],
      now: NOW,
    });
    expect(people[0]).toMatchObject({ place: 'Aftercare' });
  });

  it('home is the smallest place marked home, ties by id, and counts as a place', () => {
    const home = { lat: -33.95, lng: 18.46 };
    const { home: shown, people } = peoplePanel(MEMBERS, {
      locations: [location('m-leo', home)],
      places: [
        place('p-z', 'Holiday house', { ...home, radiusMetres: 100, home: true }),
        place('p-y', 'Home', { lat: -33.950104, lng: 18.460096, radiusMetres: 100, home: true }),
        place('p-x', 'Big home', { ...home, radiusMetres: 300, home: true }),
        place('p-s', 'School', { radiusMetres: 75 }),
      ],
      now: NOW,
    });
    expect(shown).toEqual({ lat: -33.9501, lng: 18.4601, radiusMetres: 100 });
    expect(people[0]).toMatchObject({ place: 'Home' });
  });

  it('has no home without a place marked home', () => {
    expect(
      peoplePanel(MEMBERS, { locations: [], places: [place('p-s', 'School')], now: NOW }),
    ).not.toHaveProperty('home');
  });

  it('measures as the app does', () => {
    expect(metresBetween(SCHOOL.lat, SCHOOL.lng, SCHOOL.lat + 0.001, SCHOOL.lng)).toBeCloseTo(
      111.19,
      1,
    );
  });
});

describe('a stored position and place, as the frame reads them', () => {
  const stored = {
    point: new GeoPoint(-33.96221, 18.47123),
    accuracyMetres: 12,
    reportedAt: Timestamp.fromMillis(NOW),
    sharingUntil: Timestamp.fromMillis(NOW + MINUTE),
    batteryPercent: 40,
    charging: true,
    motion: 'driving',
  };

  it('keeps the position, the stamp, the lease and the mode, and nothing about the phone', () => {
    expect(parsed(frameStoredLocation, { ...stored, mode: 'continuous' })).toEqual({
      lat: -33.96221,
      lng: 18.47123,
      accuracyMetres: 12,
      reportedAt: NOW,
      sharingUntil: NOW + MINUTE,
      continuous: true,
    });
  });

  it('reads a missing or unknown mode as a window, and a missing stamp as not yet stamped', () => {
    const unstamped = Object.fromEntries(
      Object.entries(stored).filter(([key]) => key !== 'reportedAt'),
    );
    expect(parsed(frameStoredLocation, unstamped)).toMatchObject({
      reportedAt: null,
      continuous: false,
    });
    expect(parsed(frameStoredLocation, { ...stored, mode: 'later' })).toMatchObject({
      continuous: false,
    });
  });

  it('leaves off a position that does not parse', () => {
    expect(parsed(frameStoredLocation, { ...stored, point: { lat: 1, lng: 2 } })).toBeNull();
    expect(parsed(frameStoredLocation, { ...stored, accuracyMetres: -1 })).toBeNull();
    expect(parsed(frameStoredLocation, { ...stored, sharingUntil: null })).toBeNull();
  });

  it('a place is home only by its icon', () => {
    const school = {
      name: 'School',
      centre: new GeoPoint(-33.96, 18.47),
      radiusMetres: 150,
      icon: 'school',
      alerts: {},
    };
    expect(parsed(frameStoredPlace, school)).toEqual({
      name: 'School',
      lat: -33.96,
      lng: 18.47,
      radiusMetres: 150,
      home: false,
    });
    expect(parsed(frameStoredPlace, { ...school, icon: 'home' })).toMatchObject({ home: true });
    expect(parsed(frameStoredPlace, { ...school, centre: null })).toBeNull();
  });
});
