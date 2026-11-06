import type { EmailMessage } from '../shared/email_sender';

export const PUBLIC_SITE_ORIGIN = 'https://app.nestprep.io';

const INK = '#35252e';
const INK_SECONDARY = '#6e5f65';
const CANVAS = '#fff8ed';
const SURFACE = '#f5e9d7';
const OUTLINE = '#d6c2a8';
const BODY_FONT = "'DM Sans', 'Helvetica Neue', Helvetica, Arial, sans-serif";
const HEADING_FONT = "Fraunces, Georgia, 'Times New Roman', serif";

export function escapeHtml(value: string): string {
  return value
    .replaceAll('&', '&amp;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;')
    .replaceAll('"', '&quot;')
    .replaceAll("'", '&#39;');
}

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
  return `<!doctype html>
<html lang="en">
  <head>
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1" />
    <meta name="color-scheme" content="light only" />
    <meta name="supported-color-schemes" content="light only" />
    <title>Reset your NestPrep password</title>
  </head>
  <body style="margin:0;padding:0;background-color:${CANVAS};">
    <div style="display:none;max-height:0;overflow:hidden;mso-hide:all;">Choose a new password for ${address}. The link works once, for one hour.</div>
    <table role="presentation" width="100%" cellpadding="0" cellspacing="0" border="0" style="background-color:${CANVAS};">
      <tr>
        <td align="center" style="padding:32px 16px;">
          <table role="presentation" width="100%" cellpadding="0" cellspacing="0" border="0" style="max-width:520px;">
            <tr>
              <td align="center" style="padding:0 0 24px 0;">
                <img src="${PUBLIC_SITE_ORIGIN}/assets/nest_mark.png" width="56" height="56" alt="NestPrep" style="display:block;border:0;outline:none;width:56px;height:56px;" />
              </td>
            </tr>
            <tr>
              <td style="background-color:#ffffff;border:1px solid ${OUTLINE};border-radius:20px;padding:36px 32px;">
                <h1 style="margin:0 0 16px 0;font-family:${HEADING_FONT};font-size:26px;line-height:32px;font-weight:600;color:${INK};">Reset your password</h1>
                <p style="margin:0 0 24px 0;font-family:${BODY_FONT};font-size:16px;line-height:24px;color:${INK};">Somebody asked to reset the NestPrep password for <strong>${address}</strong>. If it was you, choose a new one here.</p>
                <table role="presentation" cellpadding="0" cellspacing="0" border="0" style="margin:0 0 24px 0;">
                  <tr>
                    <td align="center" bgcolor="${INK}" style="border-radius:999px;">
                      <a href="${href}" target="_blank" style="display:inline-block;padding:14px 28px;font-family:${BODY_FONT};font-size:16px;line-height:20px;font-weight:600;color:${CANVAS};text-decoration:none;border-radius:999px;">Set a new password</a>
                    </td>
                  </tr>
                </table>
                <p style="margin:0 0 8px 0;font-family:${BODY_FONT};font-size:14px;line-height:20px;color:${INK_SECONDARY};">The link works once, for one hour. If the button does not open, paste this into your browser:</p>
                <p style="margin:0 0 24px 0;font-family:${BODY_FONT};font-size:13px;line-height:20px;word-break:break-all;"><a href="${href}" target="_blank" style="color:${INK};text-decoration:underline;">${href}</a></p>
                <table role="presentation" width="100%" cellpadding="0" cellspacing="0" border="0">
                  <tr>
                    <td style="background-color:${SURFACE};border-radius:12px;padding:14px 16px;font-family:${BODY_FONT};font-size:14px;line-height:20px;color:${INK_SECONDARY};">If you did not ask for this, you can ignore this email. Your password has not changed.</td>
                  </tr>
                </table>
              </td>
            </tr>
            <tr>
              <td align="center" style="padding:24px 16px 0 16px;font-family:${BODY_FONT};font-size:12px;line-height:18px;color:${INK_SECONDARY};">
                NestPrep · school lunches, sorted before Sunday night<br />
                <a href="${PUBLIC_SITE_ORIGIN}" style="color:${INK_SECONDARY};">app.nestprep.io</a> · <a href="${PUBLIC_SITE_ORIGIN}/privacy" style="color:${INK_SECONDARY};">Privacy</a>
              </td>
            </tr>
          </table>
        </td>
      </tr>
    </table>
  </body>
</html>
`;
}
