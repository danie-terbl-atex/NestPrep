import type { EmailMessage } from '../shared/email_sender';
import {
  PUBLIC_SITE_ORIGIN,
  accountEmailHtml,
  emailAside,
  emailButton,
  emailFallbackLink,
  emailHeading,
  emailParagraph,
  escapeHtml,
} from './account_email';

export function resetPageLink(firebaseLink: string): string | null {
  const oobCode = new URL(firebaseLink).searchParams.get('oobCode');
  if (oobCode === null || oobCode === '') return null;
  return `${PUBLIC_SITE_ORIGIN}/reset-password?oobCode=${encodeURIComponent(oobCode)}`;
}

export function passwordResetMessage(to: string, link: string): EmailMessage {
  return {
    to,
    subject: 'Reset your NestPrep password',
    text: [
      'Hello,',
      '',
      `Somebody asked to reset the NestPrep password for ${to}. If it was you, open this link to choose a new one:`,
      '',
      link,
      '',
      'The link works once, for one hour.',
      '',
      'If you did not ask for this, you can ignore this email. Your password has not changed.',
      '',
      'NestPrep',
      PUBLIC_SITE_ORIGIN,
    ].join('\n'),
    html: passwordResetHtml(to, link),
  };
}

function passwordResetHtml(to: string, link: string): string {
  const address = escapeHtml(to);
  const href = escapeHtml(link);
  return accountEmailHtml({
    title: 'Reset your NestPrep password',
    preheader: `Choose a new password for ${address}. The link works once, for one hour.`,
    content: [
      emailHeading('Reset your password'),
      emailParagraph(
        `Somebody asked to reset the NestPrep password for <strong>${address}</strong>. If it was you, choose a new one here.`,
      ),
      emailButton(href, 'Set a new password'),
      emailFallbackLink(
        href,
        'The link works once, for one hour. If the button does not open, paste this into your browser:',
      ),
      emailAside(
        'If you did not ask for this, you can ignore this email. Your password has not changed.',
      ),
    ].join('\n                '),
  });
}
