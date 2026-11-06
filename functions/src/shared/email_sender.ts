import { type HttpClient, fetchHttpClient } from './http_client';

export interface EmailMessage {
  readonly to: string;
  readonly subject: string;
  readonly text: string;
  readonly html?: string;
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
          ...(message.html === undefined ? {} : { html: message.html }),
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
