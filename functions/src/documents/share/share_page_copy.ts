/**
 * Every word on the shared-link page (documents ADR-0006) — the one NestPrep
 * surface a person without the app reads, so it says what happened in plain
 * words and never shows a code, a token or a reason a stranger could use
 * (`FE-09`). The page title never names the document: a chat app's link
 * preview reads it.
 */
export const SHARE_PAGE_COPY = {
  pageTitle: 'A document shared with you · NestPrep',
  brand: 'NestPrep',
  sharedBy: (household: string) => `${household} shared this with you`,
  openPdf: 'Open the PDF',
  pdfNote: 'It opens in your browser. Nothing is installed.',
  footer:
    'Please do not forward this link. It stops working when it ends, or sooner if it is stopped.',
  pinTitle: 'Enter the PIN',
  pinBody: 'Whoever sent this link gave you a PIN with it.',
  pinLabel: 'PIN',
  pinSubmit: 'Open the document',
  wrongPin: (left: number) =>
    left === 1
      ? 'That PIN is not right. You have one try left.'
      : `That PIN is not right. You have ${String(left)} tries left.`,
  expiredTitle: 'This link has expired',
  expiredBody: 'Ask whoever sent it for a new one.',
  endedTitle: 'This link no longer works',
  endedBody: 'It was stopped, or the document was removed. Ask whoever sent it for a new one.',
  lockedTitle: 'This link is locked',
  lockedBody: 'The PIN was wrong too many times. Ask whoever sent it for a new link.',
  notFoundTitle: 'This link does not work',
  notFoundBody: 'Check that it was copied in full, or ask whoever sent it for a new one.',
} as const;

/** When a link ends, in words, on the household's clock. */
export function endsLabel(input: {
  expiresAt: Date;
  untilShiftEnds: boolean;
  timeZone: string;
}): string {
  const when = new Intl.DateTimeFormat('en-GB', {
    timeZone: input.timeZone,
    weekday: 'short',
    day: 'numeric',
    month: 'short',
    hour: '2-digit',
    minute: '2-digit',
    hourCycle: 'h23',
  }).format(input.expiresAt);
  return input.untilShiftEnds
    ? `Available until the shift ends, and never after ${when}`
    : `Available until ${when}`;
}
