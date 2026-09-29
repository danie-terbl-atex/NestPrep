/**
 * What an event means somebody packs (notifications ADR-0002: *a bag is
 * today's lunch boxes, plus kit the day's events call for*).
 *
 * No feature stores bags, and inventing a "bag" document for the digest would
 * be a second copy of the calendar. So the kit is read off the event's own
 * title with a short, fixed vocabulary — whole words, any case. It is a
 * reminder, not a rule: a miss costs a line in the digest, never a refusal.
 */

interface KitWord {
  readonly pattern: RegExp;
  readonly kit: string;
}

const KIT_WORDS: readonly KitWord[] = [
  { pattern: /\b(swim|swimming|gala)\b/i, kit: 'Swimming kit' },
  { pattern: /\b(soccer|football)\b/i, kit: 'Soccer kit' },
  { pattern: /\brugby\b/i, kit: 'Rugby kit' },
  { pattern: /\bnetball\b/i, kit: 'Netball kit' },
  { pattern: /\bhockey\b/i, kit: 'Hockey kit' },
  { pattern: /\bcricket\b/i, kit: 'Cricket kit' },
  { pattern: /\btennis\b/i, kit: 'Tennis kit' },
  { pattern: /\b(ballet|dance|dancing)\b/i, kit: 'Dance kit' },
  { pattern: /\b(karate|judo|taekwondo)\b/i, kit: 'Martial-arts kit' },
  { pattern: /\b(gym|gymnastics|pe|athletics|sport|sports|cross country)\b/i, kit: 'Sports kit' },
  { pattern: /\blibrary\b/i, kit: 'Library books' },
  { pattern: /\b(music|piano|guitar|violin|recorder)\b/i, kit: 'Instrument and music' },
];

/** The kit [title] calls for, or null when it calls for none. */
export function kitFor(title: string): string | null {
  return KIT_WORDS.find((word) => word.pattern.test(title))?.kit ?? null;
}
