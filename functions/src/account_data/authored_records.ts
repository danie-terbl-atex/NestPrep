/**
 * Where a household keeps what one person made, and the field that says so
 * — the member id the rules stamp with `isOwnMember`. An export lists these
 * so a person can see what they put into each household (accounts ADR-0006).
 *
 * They are the household's records and stay when an account is deleted: the
 * profile they name stays too, unclaimed (household ADR-0001). A collection
 * added later that stamps authorship belongs here, which
 * `test/unit/account_data_inventory.test.ts` checks against the rules.
 */
export const AUTHORED_RECORDS: readonly { collection: string; authorField: string }[] = [
  { collection: 'events', authorField: 'createdBy' },
  { collection: 'tasks', authorField: 'createdBy' },
  { collection: 'routines', authorField: 'createdBy' },
  { collection: 'groceryItems', authorField: 'addedBy' },
  { collection: 'meals', authorField: 'addedBy' },
  { collection: 'lunchItems', authorField: 'addedBy' },
  { collection: 'lunchFavourites', authorField: 'createdBy' },
  { collection: 'documentFolders', authorField: 'createdBy' },
  { collection: 'documents', authorField: 'uploadedBy' },
  { collection: 'rewards', authorField: 'createdBy' },
  { collection: 'rewardRequests', authorField: 'requestedBy' },
  { collection: 'homeCareJobs', authorField: 'createdBy' },
  { collection: 'homeCareProducts', authorField: 'createdBy' },
  { collection: 'homeCareRooms', authorField: 'createdBy' },
  { collection: 'nannyContacts', authorField: 'createdBy' },
  { collection: 'nannyGuide', authorField: 'createdBy' },
  { collection: 'nannyRules', authorField: 'createdBy' },
  { collection: 'nannyShifts', authorField: 'carerMemberId' },
];

/** The most records of one kind an export lists; past it, the export says so (`BE-08`). */
export const AUTHORED_LIMIT = 200;
