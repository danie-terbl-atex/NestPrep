import type { EmailMessage } from '../shared/email_sender';
import {
  BODY_FONT,
  INK,
  PUBLIC_SITE_ORIGIN,
  accountEmailHtml,
  emailAside,
  emailButton,
  emailFallbackLink,
  emailHeading,
  emailParagraph,
  escapeHtml,
} from './account_email';

const GUAVA = '#f57b91';
const SUPPORT_ADDRESS = 'admin@nestprep.io';

const WHAT_NESTPREP_DOES = [
  'Lunchboxes for the week, planned in a few taps',
  'One grocery list the whole household adds to',
  'The family calendar and chores, together in one place',
  'Invite the people you share your home with, so it is not all on you',
] as const;

export function verifyPageLink(firebaseLink: string): string | null {
  const oobCode = new URL(firebaseLink).searchParams.get('oobCode');
  if (oobCode === null || oobCode === '') return null;
  return `${PUBLIC_SITE_ORIGIN}/verify-email?oobCode=${encodeURIComponent(oobCode)}`;
}

export function firstNameOf(displayName: string | undefined): string | null {
  const first = displayName?.trim().split(/\s+/u)[0]?.slice(0, 40) ?? '';
  return first === '' ? null : first;
}

export function welcomeMessage(
  to: string,
  firstName: string | null,
  confirmLink: string | null,
): EmailMessage {
  const greeting = firstName === null ? 'Welcome to NestPrep' : `Welcome to NestPrep, ${firstName}`;
  return {
    to,
    subject: greeting,
    text: welcomeText(to, greeting, confirmLink),
    html: welcomeHtml(to, greeting, confirmLink),
  };
}

function welcomeText(to: string, greeting: string, confirmLink: string | null): string {
  return [
    `${greeting}!`,
    '',
    "You're in. NestPrep moves the week's plans out of one person's head and into one place your whole household can see:",
    '',
    ...WHAT_NESTPREP_DOES.map((line) => `- ${line}`),
    '',
    ...(confirmLink === null
      ? []
      : [
          'One small thing: confirm this is your email, so we can always help you back in if you forget your password.',
          '',
          confirmLink,
          '',
        ]),
    'Open the app whenever you are ready. A first little win: tomorrow’s lunchbox.',
    '',
    `This account was made with ${to}. If that wasn't you, write to ${SUPPORT_ADDRESS} and we will sort it out.`,
    '',
    'See you inside,',
    'NestPrep',
    PUBLIC_SITE_ORIGIN,
  ].join('\n');
}

function emailList(items: readonly string[]): string {
  const rows = items
    .map(
      (item) => `<tr>
                    <td width="20" valign="top" style="padding:0 0 12px 0;font-family:${BODY_FONT};font-size:16px;line-height:24px;color:${GUAVA};">&#9679;</td>
                    <td style="padding:0 0 12px 0;font-family:${BODY_FONT};font-size:16px;line-height:24px;color:${INK};">${escapeHtml(item)}</td>
                  </tr>`,
    )
    .join('\n                  ');
  return `<table role="presentation" cellpadding="0" cellspacing="0" border="0" style="margin:0 0 12px 0;">
                  ${rows}
                </table>`;
}

function confirmSection(href: string): string {
  return [
    emailParagraph(
      '<strong>One small thing:</strong> confirm this is your email, so we can always help you back in if you forget your password.',
    ),
    emailButton(href, 'Confirm my email'),
    emailFallbackLink(href, 'If the button does not open, paste this into your browser:'),
  ].join('\n                ');
}

function welcomeHtml(to: string, greeting: string, confirmLink: string | null): string {
  const address = escapeHtml(to);
  const title = escapeHtml(greeting);
  return accountEmailHtml({
    title,
    preheader: "You're in. Here's what NestPrep takes off your plate this week.",
    content: [
      emailHeading(title),
      emailParagraph(
        "You're in. NestPrep moves the week's plans out of one person's head and into one place your whole household can see.",
      ),
      emailList(WHAT_NESTPREP_DOES),
      ...(confirmLink === null ? [] : [confirmSection(escapeHtml(confirmLink))]),
      emailParagraph(
        'Open the app whenever you are ready. A first little win: tomorrow’s lunchbox.',
      ),
      emailAside(
        `This account was made with <strong>${address}</strong>. If that wasn't you, write to <a href="mailto:${SUPPORT_ADDRESS}" style="color:${INK};">${SUPPORT_ADDRESS}</a> and we will sort it out.`,
      ),
    ].join('\n                '),
  });
}
