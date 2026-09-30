/**
 * The family's calendar across this week and next (calendar ADR-0001; the
 * recurrence shape of foundation ADR-0005): school runs, lessons and sport
 * that repeat, one-offs, all-day days, a school holiday that skips the runs.
 * Times are minutes since midnight; an event with no start is all day; an
 * empty `memberIds` is everybody.
 */
import { minuteOf, writeAll } from './context.mjs';
import { WHO } from './cast.mjs';

const { mom, dad, gran, helper, nanny, lerato, sipho, zoe } = WHO;

const weekly = (weekdays, until = null) => ({ frequency: 'weekly', interval: 1, weekdays, until });
const daily = (until) => ({ frequency: 'daily', interval: 1, weekdays: [], until });

/** [id, title, dayOffset, start, end, memberIds, createdBy, recurrence?, note?] */
function events(ctx) {
  const { day } = ctx;
  return [
    // What happens every week, started last week so it has a history.
    [
      'school-run',
      'School run',
      -7,
      '07:10',
      '07:45',
      [dad, lerato, sipho],
      dad,
      weekly([1, 2, 3, 4, 5]),
    ],
    [
      'sipho-pickup',
      'Sipho pickup — Oakwood',
      -7,
      '12:30',
      '13:00',
      [nanny, sipho],
      mom,
      weekly([1, 2, 3, 4, 5]),
      'Grade R finishes at half twelve.',
    ],
    [
      'lerato-pickup',
      'Lerato pickup — Jacaranda',
      -7,
      '14:30',
      '15:00',
      [nanny, lerato],
      mom,
      weekly([1, 2, 3, 4, 5]),
    ],
    [
      'swimming',
      'Swimming — Lerato',
      -6,
      '15:30',
      '16:30',
      [lerato, mom],
      mom,
      weekly([2, 4]),
      'Costume, towel, goggles.',
    ],
    [
      'soccer',
      'Soccer practice — Sipho',
      -5,
      '15:00',
      '16:00',
      [sipho, dad],
      dad,
      weekly([3]),
      'Shin pads!',
    ],
    [
      'piano',
      'Piano lesson',
      -7,
      '16:30',
      '17:15',
      [lerato],
      mom,
      weekly([1]),
      'Mrs Venter, practise book in the bag.',
    ],
    ['netball', 'Netball match', -2, '09:00', '10:30', [lerato, dad], dad, weekly([6])],
    ['music-class', 'Toddler music class', -3, '09:30', '10:15', [zoe, gran], gran, weekly([5])],
    ['bible-study', 'Bible study', -4, '10:00', '11:30', [gran], gran, weekly([4])],
    ['gym', 'Gym', -7, '06:00', '07:00', [dad], dad, weekly([1, 3, 5])],
    [
      'bins',
      'Refuse collection',
      -6,
      null,
      null,
      [],
      dad,
      weekly([2]),
      'Bins out the night before.',
    ],
    ['sunday-braai', 'Family braai', -1, '17:00', '20:00', [], dad, weekly([7])],
    // This week.
    [
      'plumber',
      'Plumber — geyser service',
      0,
      '09:00',
      '11:00',
      [helper],
      mom,
      null,
      'Let him in at the side gate.',
    ],
    ['gran-eyes', 'Eye test', 1, '11:00', '11:45', [gran], gran],
    [
      'date-night',
      'Date night',
      2,
      '18:30',
      '22:30',
      [mom, dad],
      mom,
      null,
      'Lindiwe is babysitting.',
    ],
    [
      'dentist',
      'Dentist — Sipho',
      3,
      '10:30',
      '11:00',
      [sipho, mom],
      mom,
      null,
      'Dr Pillay, Rosebank. Check-up and clean.',
    ],
    ['civvies', 'Civvies day — R10 for charity', 4, null, null, [lerato], mom],
    [
      'birthday-dinner',
      'Birthday dinner for Naledi',
      4,
      '19:00',
      '22:00',
      [mom, dad],
      dad,
      null,
      'Table for two, booked.',
    ],
    [
      'amahle-party',
      "Amahle's birthday party",
      5,
      '11:00',
      '13:00',
      [lerato, mom],
      mom,
      null,
      'Zoo Lake picnic spot. Gift wrapped.',
    ],
    // Next week.
    ['car-service', 'Car service — Polo', 7, '08:00', '09:00', [dad], dad],
    [
      'planetarium',
      'School tour — Planetarium',
      7,
      null,
      null,
      [lerato],
      mom,
      null,
      'Packed lunch, R50 in an envelope.',
    ],
    ['cape-town', 'Pieter in Cape Town', 8, null, null, [dad], dad, daily(day(9))],
    ['parents-evening', "Parents' evening — Jacaranda Prep", 9, '18:00', '19:30', [mom, gran], mom],
    [
      'clinic',
      'Clinic — Zoë check-up',
      10,
      '09:00',
      '09:45',
      [zoe, mom],
      mom,
      null,
      'Road-to-health book.',
    ],
    ['book-club', 'Book club', 10, '19:00', '21:30', [mom], mom],
    ['school-holiday', 'School holiday — schools closed', 11, null, null, [lerato, sipho], mom],
    [
      'sipho-party',
      "Sipho's 6th birthday party",
      12,
      '14:00',
      '17:00',
      [],
      mom,
      null,
      'Dinosaur theme. Jumping castle arrives at 13:00.',
    ],
    ['church', 'Church', 13, '09:00', '10:30', [gran, zoe], gran],
  ].map(
    ([id, title, offset, start, end, memberIds, createdBy, recurrence = null, note = null]) => ({
      id,
      data: {
        title,
        note,
        date: day(offset),
        startMinute: start === null ? null : minuteOf(start),
        endMinute: end === null ? null : minuteOf(end),
        recurrence,
        memberIds,
        createdBy,
        createdAt: ctx.at(day(Math.min(offset, 0) - 7), '20:00'),
      },
    }),
  );
}

export async function seedCalendar(ctx) {
  const list = events(ctx);
  const docs = list.map(({ id, data }) => [ctx.col('events').doc(`demo-${id}`), data]);
  // The holiday Friday has no school runs or pickups.
  const holiday = ctx.day(11);
  for (const eventId of ['school-run', 'sipho-pickup', 'lerato-pickup']) {
    docs.push([
      ctx.col('eventExceptions').doc(`demo-${eventId}_${holiday}`),
      {
        eventId: `demo-${eventId}`,
        occurrenceDate: holiday,
        skippedBy: mom,
        skippedAt: ctx.at(ctx.day(0), '19:00'),
      },
    ]);
  }
  await writeAll(ctx.store, docs);
  return `calendar: ${String(list.length)} events (${String(list.filter((e) => e.data.recurrence).length)} repeating), 3 skipped occurrences`;
}
