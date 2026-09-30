/**
 * Two finished shifts for Lindiwe, the day before yesterday and yesterday:
 * the handover log (a meal, a nap, the asthma pump, a bumped knee), a photo
 * from the park, the checklists ticked, and the summary worked out by
 * `summariseShift` — the same code `endNannyShift` runs. The summaries and
 * the photo are written as waiting for delivery, so the Functions' own
 * triggers put the handover and photo notices in the family's inbox.
 */
import { readFileSync } from 'node:fs';
import { createRequire } from 'node:module';
import { resolve } from 'node:path';

import { addDays, writeAll } from './context.mjs';
import { WHO, uidOf } from './cast.mjs';
import { checklistDocs } from './nanny.mjs';

const require = createRequire(import.meta.url);
const { summariseShift } = require('../../lib/nanny_hub/shift_summary.js');

const { nanny, lerato, sipho, zoe } = WHO;

/** [id, days before today, from, to, entries: [kind, at, note, mood, childIds, photo?], closing note] */
const SHIFTS = [
  [
    'earlier',
    2,
    '12:15',
    '18:30',
    [
      ['meal', '13:20', 'Sipho ate all his sandwich and the grapes.', null, [sipho]],
      ['nap', '13:05', 'Zoë down for a nap, slept till 14:30.', null, [zoe]],
      ['note', '15:40', 'Lerato finished her reading log.', null, [lerato]],
      ['mood', '17:00', null, 'happy', [sipho, zoe]],
    ],
    'Easy afternoon. Everyone fed and bathed.',
  ],
  [
    'yesterday',
    1,
    '12:15',
    '18:45',
    [
      ['meal', '13:15', 'Snack: rice cakes and apple.', null, [sipho]],
      ['nap', '13:00', 'Short nap today, 45 minutes.', null, [zoe]],
      ['nappy', '14:00', 'Changed. All good.', null, [zoe]],
      [
        'medicine',
        '16:10',
        'Lerato wheezy after swimming — two puffs of the blue pump, fine after.',
        null,
        [lerato],
      ],
      ['note', '16:30', 'Park after swimming!', null, [sipho, zoe], 'photo'],
      [
        'incident',
        '17:05',
        'Sipho bumped his knee on the jungle gym. Ice and a plaster, no tears for long.',
        'upset',
        [sipho],
      ],
      ['mood', '18:00', null, 'tired', [lerato, sipho, zoe]],
    ],
    'Busy one. Lerato used her pump once (see log). Sipho has a plaster on his left knee.',
  ],
];

const PHOTO_ID = 'demo-park-photo-01';

export async function seedNannyShifts(ctx) {
  const { day, at, col, cast, bucket } = ctx;
  const docs = [];
  const checklists = checklistDocs(at(day(-21), '20:00'));
  await bucket
    .file(`households/${cast.householdId}/nannyHub/${PHOTO_ID}`)
    .save(readFileSync(resolve(import.meta.dirname, 'images/park.jpg')), {
      contentType: 'image/jpeg',
      resumable: false,
      metadata: { metadata: { uploadedByUid: uidOf(nanny) } },
    });

  const allTicks = Object.entries(checklists).flatMap(([moment, list]) =>
    list.items.map((item) => `${moment}:${item.id}`),
  );
  for (const [id, offset, from, to, entries, closingNote] of SHIFTS) {
    const shiftId = `demo-shift-${id}`;
    const date = addDays(ctx.today, -offset);
    const shift = col('nannyShifts').doc(shiftId);
    const ticks = Object.fromEntries(
      allTicks
        .slice(0, id === 'earlier' ? allTicks.length : allTicks.length - 2)
        .map((key) => [key, true]),
    );
    const stored = entries.map(([kind, time, note, mood, childIds, photo]) => ({
      kind,
      note,
      mood,
      childIds,
      photoId: photo ? PHOTO_ID : null,
      at: at(date, time),
      byMemberId: nanny,
      createdAt: at(date, time),
    }));
    stored.forEach((entry, index) =>
      docs.push([shift.collection('entries').doc(`demo-entry-${String(index + 1)}`), entry]),
    );
    if (entries.some((entry) => entry[5])) {
      docs.push([
        shift.collection('photoUpdates').doc('demo-photo-1'),
        {
          photoId: PHOTO_ID,
          caption: 'Park after swimming!',
          childIds: [sipho, zoe],
          byMemberId: nanny,
          createdAt: at(date, '16:30'),
          delivery: { state: 'pending' },
        },
      ]);
    }
    docs.push([
      shift,
      {
        carerMemberId: nanny,
        startedBy: nanny,
        startedAt: at(date, from),
        endedAt: at(date, to),
        endedBy: nanny,
        status: 'ended',
        ticks,
      },
    ]);
    const summary = summariseShift({ entries: stored, ticks, checklists });
    docs.push([
      col('nannyShiftSummaries').doc(shiftId),
      {
        ...summary,
        carerMemberId: nanny,
        startedAt: at(date, from),
        endedAt: at(date, to),
        endedBy: nanny,
        closingNote,
        delivery: { state: 'pending' },
      },
    ]);
  }

  await writeAll(ctx.store, docs);
  return `nanny shifts: ${String(SHIFTS.length)} ended with logs and summaries, 1 photo update`;
}
