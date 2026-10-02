/**
 * A South African mobile number as Checkers wants it — E.164, `+27` then nine
 * digits starting 6, 7 or 8 — from however a person typed it: `082 123 4567`,
 * `+27 82 123 4567`, `27821234567`. Null when it is not one.
 */
export function normaliseSaMobile(typed: string): string | null {
  const digits = typed.replace(/[\s\-().]/g, '');
  let national: string | null = null;
  if (/^0\d{9}$/.test(digits)) national = digits.slice(1);
  else if (/^\+27\d{9}$/.test(digits)) national = digits.slice(3);
  else if (/^27\d{9}$/.test(digits)) national = digits.slice(2);
  if (national === null || !/^[678]/.test(national)) return null;
  return `+27${national}`;
}

/**
 * What the app shows and the link document keeps: the last four digits only,
 * so a stored link never holds a whole number (ENG-22, POPIA).
 */
export function maskMobile(e164: string): string {
  return `+27 ** *** ${e164.slice(-4)}`;
}
