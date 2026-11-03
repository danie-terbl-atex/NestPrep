import { type HttpClient, fetchHttpClient } from '../shared/http_client';

export interface EmailMessage {
  readonly to: string;
  readonly subject: string;
  readonly text: string;
}

export interface EmailSender {
  send(message: EmailMessage): Promise<void>;
}

export class EmailNotSent extends Error {
  constructor(readonly why: string) {
    super(`email not sent: ${why}`);
    this.name = 'EmailNotSent';
  }
}

export const RESEND_ENDPOINT = 'https://api.resend.com/emails';

export function resendEmailSender(
  config: { readonly apiKey: string | null; readonly from: string | null },
  http: HttpClient = fetchHttpClient,
): EmailSender {
  return {
    async send(message: EmailMessage): Promise<void> {
      if (config.apiKey === null || config.from === null) throw new EmailNotSent('notConfigured');
      const response = await http.send(RESEND_ENDPOINT, {
        method: 'POST',
        headers: {
          Authorization: `Bearer ${config.apiKey}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          from: config.from,
          to: [message.to],
          subject: message.subject,
          text: message.text,
        }),
      });
      if (response.status < 200 || response.status >= 300) {
        throw new EmailNotSent(`status ${String(response.status)}`);
      }
    },
  };
}

export const silentEmailSender: EmailSender = {
  async send(): Promise<void> {
    await Promise.resolve();
  },
};

export function emailCodeMessage(to: string, code: string): EmailMessage {
  return {
    to,
    subject: `${code} is your NestPrep code`,
    text: [
      `Your NestPrep code is ${code}.`,
      '',
      'Type it in the NestPrep app to add this email to your account. It works for 10 minutes.',
      '',
      'If you did not ask for this code, you can ignore this email.',
    ].join('\n'),
  };
}
