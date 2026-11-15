/**
 * The free demo family in the real project: two parents who sign in and one
 * child who does not, on the free tier, so a store reviewer reaches the
 * paywall with something to buy. Every top-level id starts with `free-`;
 * names are invented. The password is the demo accounts' own.
 */
export const FREE_PREFIX = 'free-';

export const FREE_WHO = { mom: 'ayanda', dad: 'thabo', child: 'kayla' };

export const FREE_CAST = {
  householdId: 'free-maple-lane',
  name: 'The Maple Lane Nest',
  timeZone: 'Africa/Johannesburg',
  people: [
    {
      uid: 'free-parent',
      email: 'free-parent@nestprep.test',
      displayName: 'Ayanda Dlamini',
      memberId: FREE_WHO.mom,
      role: 'admin',
      color: 'teal',
      birthday: '1990-02-17',
    },
    {
      uid: 'free-partner',
      email: 'free-partner@nestprep.test',
      displayName: 'Thabo Dlamini',
      memberId: FREE_WHO.dad,
      role: 'parent',
      color: 'indigo',
      birthday: '1988-09-05',
    },
  ],
  children: [
    {
      memberId: FREE_WHO.child,
      displayName: 'Kayla',
      color: 'violet',
      birthday: '2019-06-21',
      profile: {
        grade: 'Grade 1',
        likes: ['pasta', 'strawberries', 'ballet'],
        dislikes: ['mushrooms'],
      },
    },
  ],
  schools: [],
};
