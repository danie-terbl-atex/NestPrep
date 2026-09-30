/**
 * The nanny hub (nanny-hub ADR-0001 onward): a card per child, who to call,
 * the emergency sheet, the house guide and rules, the five checklists, two
 * house codes, and tonight's booking for Lindiwe with its pass. The finished
 * shifts are `nanny-shifts.mjs`, pickups `nanny-pickups.mjs`.
 */
import { minuteOf, writeAll } from './context.mjs';
import { WHO } from './cast.mjs';

const { mom, nanny, lerato, sipho, zoe } = WHO;

const CARDS = {
  [lerato]: {
    routines: [
      ['Homework at the kitchen table', '15:30', 'Reading log signed every night.'],
      ['Asthma pump if wheezy', null, 'Blue pump, two puffs, in her school bag.'],
      ['Shower', '19:00'],
    ],
    comfortItems: ['Her sketchbook', 'Netball'],
    settling: 'Chat about her day first; she winds down with drawing.',
    goodToKnow: 'Mild dairy allergy — a little cheese is fine, no milk to drink.',
  },
  [sipho]: {
    routines: [
      ['Snack after pickup', '13:15', 'Nut-free only!'],
      ['Soccer in the garden', '16:00'],
      ['Bath', '18:00'],
      ['Bed', '19:00', 'Two dinosaur stories.'],
    ],
    comfortItems: ['Rex the dinosaur', 'Night light on'],
    settling: 'Back rub and the dinosaur song.',
    goodToKnow:
      'SEVERE peanut allergy. EpiPen in the red pouch of his bag and in the kitchen drawer.',
  },
  [zoe]: {
    routines: [
      ['Nap', '13:00', 'About an hour and a half.'],
      ['Bottle', '18:15'],
      ['Bed', '18:45'],
    ],
    comfortItems: ['Bunny blankie', 'Dummy (bedtime only)'],
    settling: 'Rock her with the white-noise app on.',
    goodToKnow: 'Kiwi gives her a rash.',
  },
};

const CONTACTS = [
  ['Naledi (mom)', 'parent', '+27 82 555 0101', null],
  ['Pieter (dad)', 'parent', '+27 83 555 0102', 'In Cape Town next Tuesday and Wednesday.'],
  ['Ouma Elsa', 'backup', '+27 72 555 0103', 'Lives five minutes away.'],
  ['Dr Pillay — paediatrician', 'doctor', '+27 11 555 0104', 'Rosebank rooms.'],
  ['Parkview Hospital (demo)', 'hospital', '+27 11 555 0105', 'Emergency unit is open all night.'],
];

const GUIDE = [
  ['First-aid kit', 'Laundry, top shelf, the red box.'],
  ['Spare EpiPen', 'Kitchen drawer left of the stove, with the instructions.'],
  ['Electricity box', 'In the garage behind the door. Prepaid meter code is on the fridge.'],
  ['Gate remote', 'Hook by the front door. The spare is in the car.'],
  ['Kids’ medicine', 'Locked tin on top of the fridge; the key is in the tea canister.'],
];

const RULES = [
  'No screens after 18:00.',
  'Nothing with nuts in the house — check every label.',
  'Homework before play.',
  'Zoë naps in her cot, not in the pram.',
  'Gate closed at all times; the dogs next door get out.',
];

const CHECKLISTS = {
  arrival: [
    'Sign in on the app',
    'Check the EpiPens are where they should be',
    'Read the notes from the morning',
  ],
  afterSchool: ['Unpack lunch boxes', 'Homework done', 'Snack (nut-free)'],
  dinner: [
    'Warm up the dinner in the fridge',
    'Children eat at the table',
    'Dishes into the dishwasher',
  ],
  bedtime: ['Bath and teeth', 'Stories', 'Lights out by 19:30'],
  beforeLeaving: ['Doors locked, alarm on', 'Write the handover note'],
};

const SECRETS = [
  ['Alarm code', '0000 (demo)', 'Press ON then the code.'],
  ['Wi-Fi', 'OakStreetNest / demo-wifi', null],
];

/** Each moment's checklist document, as the hub stores it. */
export function checklistDocs(updatedAt) {
  return Object.fromEntries(
    Object.entries(CHECKLISTS).map(([moment, texts]) => [
      moment,
      {
        items: texts.map((text, index) => ({ id: `${moment}-${String(index + 1)}`, text })),
        updatedBy: mom,
        updatedAt,
      },
    ]),
  );
}

export async function seedNanny(ctx) {
  const { day, at, col, ago } = ctx;
  const created = at(day(-21), '20:00');
  const docs = [];
  for (const [childId, card] of Object.entries(CARDS)) {
    docs.push([
      col('nannyChildCards').doc(childId),
      {
        routines: card.routines.map(([label, time, note]) => ({
          label,
          ...(time ? { minuteOfDay: minuteOf(time) } : {}),
          ...(note ? { note } : {}),
        })),
        comfortItems: card.comfortItems,
        settling: card.settling,
        goodToKnow: card.goodToKnow,
        photoId: null,
        updatedBy: mom,
        updatedAt: created,
      },
    ]);
  }
  CONTACTS.forEach(([name, kind, phone, note], index) =>
    docs.push([
      col('nannyContacts').doc(`demo-contact-${String(index + 1)}`),
      { name, kind, phone, note, createdBy: mom, createdAt: created },
    ]),
  );
  docs.push([
    col('nannyHome').doc('sheet'),
    {
      address: '12 Oak Street, Parkview, Johannesburg (demo)',
      medicalAidScheme: 'Oak Medical Aid (demo)',
      medicalAidPlan: 'Family Classic',
      medicalAidNumber: 'DEMO-0001',
      updatedBy: mom,
      updatedAt: created,
    },
  ]);
  GUIDE.forEach(([title, note], index) =>
    docs.push([
      col('nannyGuide').doc(`demo-guide-${String(index + 1)}`),
      { title, note, photoId: null, createdBy: mom, createdAt: created },
    ]),
  );
  RULES.forEach((text, index) =>
    docs.push([
      col('nannyRules').doc(`demo-rule-${String(index + 1)}`),
      { text, createdBy: mom, createdAt: created },
    ]),
  );
  for (const [moment, checklist] of Object.entries(checklistDocs(created))) {
    docs.push([col('nannyChecklists').doc(moment), checklist]);
  }
  SECRETS.forEach(([label, value, note], index) =>
    docs.push([
      col('nannySecrets').doc(`demo-secret-${String(index + 1)}`),
      { label, value, note, createdBy: mom, createdAt: created },
    ]),
  );

  // Tonight's booking (date night) and one for the party next Saturday.
  const tonight = { startsAt: at(ctx.today, '18:00'), endsAt: at(ctx.today, '23:00') };
  docs.push([
    col('nannyBookings').doc('demo-tonight'),
    {
      carerMemberId: nanny,
      ...tonight,
      note: 'Date night — home by eleven.',
      createdBy: mom,
      createdAt: at(day(-2), '19:00'),
    },
  ]);
  docs.push([
    col('nannyBookings').doc('demo-party'),
    {
      carerMemberId: nanny,
      startsAt: at(day(12), '12:30'),
      endsAt: at(day(12), '17:30'),
      note: "Extra hands for Sipho's party.",
      createdBy: mom,
      createdAt: at(day(-1), '19:00'),
    },
  ]);
  docs.push([
    col('nannyShiftPasses').doc(nanny),
    { bookingId: 'demo-tonight', ...tonight, updatedAt: ago(1) },
  ]);

  await writeAll(ctx.store, docs);
  return `nanny hub: 3 child cards, ${String(CONTACTS.length)} contacts, emergency sheet, ${String(GUIDE.length)} guide spots, ${String(RULES.length)} rules, 5 checklists, 2 codes, 2 bookings (tonight + party)`;
}
