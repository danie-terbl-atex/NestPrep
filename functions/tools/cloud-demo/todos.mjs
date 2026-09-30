/**
 * To-dos, routines and chores (todos ADR-0001, chore points ADR-0001): what
 * the grown-ups owe the week, three routines, and the children's chores with
 * stars on them. A chore is a task with `points`; its completions and stars
 * are `stars.mjs`, which needs these to exist first. Dates are the week's.
 */
import { writeAll } from './context.mjs';
import { WHO } from './cast.mjs';

const { mom, dad, gran, helper, nanny, lerato, sipho, zoe } = WHO;

const daily = { frequency: 'daily', interval: 1, weekdays: [], until: null };
const weekly = (weekdays) => ({ frequency: 'weekly', interval: 1, weekdays, until: null });

const ROUTINES = [
  ['morning', 'Morning routine', 0, daily, [lerato, sipho], 'sky', mom],
  ['bedtime', 'Bedtime', 0, daily, [lerato, sipho, zoe], 'indigo', mom],
  ['laundry', 'Laundry day', 0, weekly([1, 4]), [helper], 'amber', mom],
];

/**
 * [id, title, dueOffset, assignees, createdBy, options]. `options` carries a
 * recurrence, a routine, stars (`points`) and whether a parent checks it.
 */
const TASKS = [
  // The grown-ups' week.
  ['school-fees', 'Pay school fees — October', 4, [mom], mom, { note: 'Both schools, EFT.' }],
  ['licence-disc', 'Renew the car licence disc', 9, [dad], mom],
  ['party-venue', "Book Sipho's party venue", -3, [mom], mom],
  ['party-cake', "Order Sipho's dinosaur cake", 5, [mom], mom, { note: 'Nut-free bakery!' }],
  ['party-packs', 'Make up party packs', 10, [gran], mom],
  ['indemnity', "Sign Lerato's tour indemnity form", 3, [mom, dad], mom],
  ['library', 'Return library books', 2, [lerato], mom],
  ['pool-pump', 'Service the pool pump', 8, [dad], dad],
  ['medical-aid', "Call the medical aid about Zoë's claim", 2, [mom], mom],
  [
    'garden',
    'Water the veggie garden',
    -7,
    [gran],
    gran,
    { recurrence: { ...daily, interval: 2 } },
  ],
  ['bins', 'Take the bins out', -7, [dad], dad, { recurrence: weekly([1]) }],
  ['electricity', 'Top up the prepaid electricity', 3, [dad], mom],
  [
    'pay-thandi',
    'Pay Thandi',
    -5,
    [mom],
    mom,
    { recurrence: { frequency: 'monthly', interval: 1, weekdays: [], until: null } },
  ],
  ['school-shoes', 'Buy school shoes for Sipho', -2, [dad], mom, { note: 'UK 11, black, velcro.' }],
  ['pump-script', "Refill Lerato's asthma pump script", 1, [mom], mom],
  ['braai-clean', 'Clean the braai', 6, [dad], dad],
  ['nanny-snacks', 'Pack snacks for the park', 2, [nanny], mom],
  [
    'birthday-card',
    'Birthday card for Naledi',
    3,
    [gran, lerato, sipho],
    dad,
    { note: 'Keep it a secret!' },
  ],
  ['uniform-labels', 'Sew name labels on new jerseys', 1, [gran], mom],
  // Routine steps: the schedule comes from the routine.
  ['bed-lerato', 'Make your bed', -7, [lerato], mom, { routineId: 'morning', points: 2 }],
  ['bed-sipho', 'Make your bed', -7, [sipho], mom, { routineId: 'morning', points: 2 }],
  ['teeth', 'Brush teeth', -7, [lerato, sipho], mom, { routineId: 'morning' }],
  ['school-bag', 'Pack your school bag', -7, [lerato, sipho], mom, { routineId: 'morning' }],
  ['bath', 'Bath time', -7, [zoe, sipho], mom, { routineId: 'bedtime' }],
  ['story', 'Read a story', -7, [], mom, { routineId: 'bedtime' }],
  ['clothes', "Lay out tomorrow's clothes", -7, [lerato], mom, { routineId: 'bedtime', points: 1 }],
  ['uniforms', 'Wash school uniforms', -7, [helper], mom, { routineId: 'laundry' }],
  ['ironing', 'Iron shirts', -7, [helper], mom, { routineId: 'laundry' }],
  ['linen', 'Change the bed linen', -7, [helper], mom, { routineId: 'laundry' }],
  // Chores with stars.
  ['fish', 'Feed the fish', -2, [sipho], mom, { recurrence: daily, points: 2 }],
  ['table', 'Set the table', -1, [lerato], mom, { recurrence: daily, points: 3 }],
  [
    'tidy-room',
    'Tidy your room',
    -9,
    [lerato],
    mom,
    { recurrence: weekly([6]), points: 5, needsApproval: true },
  ],
  [
    'toys',
    'Pack away your toys',
    2,
    [sipho],
    mom,
    { recurrence: daily, points: 2, needsApproval: true },
  ],
  ['unpack', 'Help unpack the groceries', 2, [lerato, sipho], dad, { points: 3 }],
  [
    'dishwasher',
    'Empty the dishwasher',
    1,
    [lerato],
    dad,
    { recurrence: weekly([2, 4, 6]), points: 4, needsApproval: true },
  ],
];

/**
 * Every recurring thing starts where its history does, and each day gone by
 * is done — so the list shows today's work and one honest overdue errand, not
 * a week of red. Done already, as [taskId, occurrence, completedBy, doneOn?]: the ones
 * without stars. A one-off's occurrence is its due day, even when it was done
 * early.
 */
const DONE = [
  ['party-venue', -3, mom],
  ['pump-script', 1, mom, 0],
  ['library', 2, lerato, 1],
  ['bins', -7, dad],
  ['bins', 0, dad],
  ['garden', -7, gran],
  ['garden', -5, gran],
  ['garden', -3, gran],
  ['garden', -1, gran],
  ['teeth', 0, lerato],
  ['teeth', 1, sipho],
  ['school-bag', 0, sipho],
  ['school-bag', 1, lerato],
  ['bath', 0, gran],
  ['bath', 1, nanny],
  ['linen', 0, helper],
  ['garden', 1, gran],
  ['pay-thandi', -5, mom],
  ['story', 0, dad],
  ['story', 1, mom],
  ['uniforms', 0, helper],
  ['ironing', 0, helper],
  ['uniforms', -4, helper],
  ['uniform-labels', 1, gran],
];

export const taskId = (id) => `demo-${id}`;

export async function seedTodos(ctx) {
  const { day, at, col } = ctx;
  const docs = [];
  for (const [id, name, first, recurrence, assignees, color, createdBy] of ROUTINES) {
    docs.push([
      col('routines').doc(`demo-${id}`),
      {
        name,
        firstDate: day(first),
        recurrence,
        defaultAssigneeIds: assignees,
        color,
        createdBy,
        createdAt: at(day(-10), '20:00'),
      },
    ]);
  }
  for (const [id, title, due, assigneeIds, createdBy, options = {}] of TASKS) {
    docs.push([
      col('tasks').doc(taskId(id)),
      {
        title,
        note: options.note ?? null,
        dueDate: day(due),
        recurrence: options.recurrence ?? null,
        assigneeIds,
        createdBy,
        routineId: options.routineId === undefined ? null : `demo-${options.routineId}`,
        createdAt: at(day(Math.min(due, 0) - 3), '20:30'),
        points: options.points ?? 0,
        needsApproval: options.needsApproval ?? false,
      },
    ]);
  }
  for (const [id, offset, by, doneOn = offset] of DONE) {
    const date = day(offset);
    docs.push([
      col('taskCompletions').doc(`${taskId(id)}_${date}`),
      {
        taskId: taskId(id),
        occurrenceDate: date,
        completedBy: by,
        completedFor: by,
        completedAt: at(day(doneOn), doneOn >= 2 ? '07:30' : '17:30'),
      },
    ]);
  }
  await writeAll(ctx.store, docs);
  const chores = TASKS.filter(([, , , , , options]) => (options?.points ?? 0) > 0).length;
  return `todos: ${String(TASKS.length)} tasks (${String(chores)} with stars), ${String(ROUTINES.length)} routines, ${String(DONE.length)} done`;
}
