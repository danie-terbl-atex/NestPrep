/**
 * The family map (live-location ADR-0003 to ADR-0007): three places, three
 * people sharing — Naledi always and at home, Pieter always and driving, Gran
 * for an hour — and Pieter's day so far as one trail document. No place events
 * are seeded: each one would push to the demo family's real phones. Coordinates are an invented spot in Johannesburg's northern suburbs.
 */
import { GeoPoint, Timestamp } from 'firebase-admin/firestore';

import { writeAll } from './context.mjs';
import { WHO } from './cast.mjs';

const { mom, dad, gran } = WHO;

const HOME = [-26.1385, 28.0372];
const SCHOOL = [-26.1452, 28.0249];
const WORK = [-26.1076, 28.0567];

const PLACES = [
  ['demo-home', 'Home', HOME, 150, 'home', { arrive: true, leave: true }],
  ['demo-school', 'Parkhurst Primary', SCHOOL, 200, 'school', { arrive: true, leave: false }],
  ['demo-work', 'Pieter’s office', WORK, 150, 'work', { arrive: false, leave: false }],
];

const between = (from, to, share) => [
  from[0] + (to[0] - from[0]) * share,
  from[1] + (to[1] - from[1]) * share,
];

export async function seedLocation(ctx) {
  const { col, now, today } = ctx;
  const nowSeconds = Math.floor(now.getTime() / 1000);
  const inMs = (hours) => Timestamp.fromMillis(now.getTime() + hours * 3_600_000);
  const minutesAgo = (minutes) => Timestamp.fromMillis(now.getTime() - minutes * 60_000);
  const docs = PLACES.map(([id, name, [la, lo], radiusMetres, icon, alerts]) => [
    col('places').doc(id),
    { name, centre: new GeoPoint(la, lo), radiusMetres, icon, alerts, updatedAt: ctx.ago(48) },
  ]);

  const live = (point, fields) => ({
    point: new GeoPoint(point[0], point[1]),
    accuracyMetres: 12,
    reportedAt: minutesAgo(fields.minutesAgo),
    sharingUntil: inMs(fields.leaseHours),
    mode: fields.mode,
    ...fields.device,
  });
  docs.push(
    [
      col('memberLocations').doc(mom),
      live(HOME, {
        minutesAgo: 20,
        leaseHours: 24,
        mode: 'continuous',
        device: { batteryPercent: 82, charging: true, motion: 'still' },
      }),
    ],
    [
      col('memberLocations').doc(dad),
      live(between(HOME, WORK, 0.6), {
        minutesAgo: 1,
        leaseHours: 24,
        mode: 'continuous',
        device: { batteryPercent: 47, charging: false, motion: 'driving' },
      }),
    ],
    [
      col('memberLocations').doc(gran),
      live(SCHOOL, { minutesAgo: 4, leaseHours: 1, mode: 'window', device: {} }),
    ],
  );

  const points = [];
  const add = (secondsAgo, point) =>
    points.push({ t: nowSeconds - secondsAgo, la: point[0], lo: point[1], ac: 12 });
  add(3 * 3600, HOME);
  add(2 * 3600, HOME);
  for (let step = 1; step <= 8; step++) add(2 * 3600 - step * 120, between(HOME, SCHOOL, step / 8));
  add(80 * 60, SCHOOL);
  add(70 * 60, SCHOOL);
  for (let step = 1; step <= 10; step++)
    add(70 * 60 - step * 120, between(SCHOOL, WORK, step / 10));
  add(30 * 60, between(SCHOOL, WORK, 1));
  add(60, between(HOME, WORK, 0.6));
  const trail = col('locationTrails').doc(dad);
  docs.push([
    trail.collection('trailDays').doc(today),
    { points, updatedAt: minutesAgo(1), expiresAt: inMs(30 * 24) },
  ]);
  return `location: ${String(await writeAll(ctx.store, docs))} documents`;
}
