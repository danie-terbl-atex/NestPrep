export interface StepTimer {
  readonly start: number;
  readonly end: number;
  readonly seconds: number;
  readonly upToSeconds: number | null;
}

export const STEP_TIMER_MIN_SECONDS = 10;
export const STEP_TIMER_MAX_SECONDS = 12 * 60 * 60;

const FRACTIONS: Readonly<Record<string, number>> = {
  '¼': 1 / 4,
  '½': 1 / 2,
  '¾': 3 / 4,
  '⅓': 1 / 3,
  '⅔': 2 / 3,
};
const FRACTION_CHARS = Object.keys(FRACTIONS).join('');

const NUMBER = `(?:\\d+(?:\\.\\d+|\\s?[${FRACTION_CHARS}]|\\s\\d/\\d)?|\\d/\\d|[${FRACTION_CHARS}])`;
const HOURS = 'hours?|hrs?';
const MINUTES = 'minutes?|mins?';
const SECONDS = 'seconds?|secs?';
const MORE = '(?:(?:more|extra|further)\\s+)?';

const amount = (unit: string): string => `${NUMBER}\\s+${MORE}(?:${unit})\\b`;
const andThen = (unit: string): string => `(?:\\s+(?:and\\s+)?${amount(unit)})?`;

const DURATION = `(?:${amount(HOURS)}${andThen(MINUTES)}|${amount(MINUTES)}${andThen(SECONDS)}|${amount(SECONDS)})`;
const RANGE = `(?:\\s*[–-]\\s*|\\s+to\\s+)`;

const TIMER = new RegExp(
  `(?<![\\w.,/${FRACTION_CHARS}])(?:(?<low>${DURATION}|${NUMBER})${RANGE}(?<high>${DURATION})|(?<only>${DURATION}))`,
  'gi',
);
const PART = new RegExp(
  `(?<number>${NUMBER})\\s+${MORE}(?<unit>${HOURS}|${MINUTES}|${SECONDS})\\b`,
  'gi',
);
const NUMBER_PARTS = new RegExp(`^(\\d+(?:\\.\\d+)?)?\\s?(?:([${FRACTION_CHARS}])|(\\d)/(\\d))?$`);

const UNIT_SECONDS: Readonly<Record<string, number>> = { h: 3600, m: 60, s: 1 };

interface Duration {
  readonly seconds: number;
  readonly upToSeconds: number | null;
}

export function stepTimers(text: string): StepTimer[] {
  const timers: StepTimer[] = [];
  for (const match of text.matchAll(TIMER)) {
    const duration = durationOf(match.groups ?? {});
    if (duration === null) continue;
    timers.push({ start: match.index, end: match.index + match[0].length, ...duration });
  }
  return timers;
}

function durationOf({ low, high, only }: Record<string, string | undefined>): Duration | null {
  if (only !== undefined) {
    const seconds = sum(parts(only));
    return inBounds(seconds) ? { seconds, upToSeconds: null } : null;
  }
  if (low === undefined || high === undefined) return null;
  const highParts = parts(high);
  const lowParts = parts(low);
  const seconds = sum(
    lowParts.length > 0 ? lowParts : [{ number: low, unit: highParts[0]?.unit ?? '' }],
  );
  const upToSeconds = sum(highParts);
  if (!inBounds(seconds) || !inBounds(upToSeconds) || upToSeconds <= seconds) return null;
  return { seconds, upToSeconds };
}

interface Part {
  readonly number: string;
  readonly unit: string;
}

function parts(phrase: string): Part[] {
  return [...phrase.matchAll(PART)].map(({ groups }) => ({
    number: groups?.number ?? '',
    unit: groups?.unit ?? '',
  }));
}

function sum(phraseParts: readonly Part[]): number {
  const total = phraseParts.reduce(
    (seconds, { number, unit }) =>
      seconds + numberValue(number) * (UNIT_SECONDS[unit.charAt(0).toLowerCase()] ?? Number.NaN),
    0,
  );
  return Math.round(total);
}

function numberValue(number: string): number {
  const match = NUMBER_PARTS.exec(number);
  if (match === null) return Number.NaN;
  const [, whole, fraction, numerator, denominator] = match;
  const fractionValue =
    fraction !== undefined
      ? (FRACTIONS[fraction] ?? Number.NaN)
      : numerator !== undefined && denominator !== undefined
        ? Number(numerator) / Number(denominator)
        : 0;
  return Number(whole ?? 0) + fractionValue;
}

function inBounds(seconds: number): boolean {
  return seconds >= STEP_TIMER_MIN_SECONDS && seconds <= STEP_TIMER_MAX_SECONDS;
}
