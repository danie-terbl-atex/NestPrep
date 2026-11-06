import { describe, expect, it } from 'vitest';

import { emailCodeMessage } from '../../src/premium_vouchers/email_code';
import { EmailNotSent, RESEND_ENDPOINT, resendEmailSender } from '../../src/shared/email_sender';
import type { HttpClient, HttpRequest, HttpResponse } from '../../src/shared/http_client';

function recordingHttp(status: number): { http: HttpClient; sent: [string, HttpRequest][] } {
  const sent: [string, HttpRequest][] = [];
  return {
    sent,
    http: {
      send: async (url, request): Promise<HttpResponse> => {
        sent.push([url, request]);
        return Promise.resolve({ status, body: '{"id":"e1"}', location: null });
      },
    },
  };
}

const message = emailCodeMessage('sam@example.com', '482913');

describe('the email-code message', () => {
  it('is plain text carrying the code and how long it works', () => {
    expect(message.to).toBe('sam@example.com');
    expect(message.subject).toContain('482913');
    expect(message.text).toContain('482913');
    expect(message.text).toContain('10 minutes');
    expect(message.text).not.toMatch(/<[a-z]/i);
  });
});

describe('sending through Resend', () => {
  it('posts the message as JSON with the key as a bearer token', async () => {
    const { http, sent } = recordingHttp(200);
    await resendEmailSender({ apiKey: 're_test', from: 'NestPrep <hello@nestprep.io>' }, http).send(
      message,
    );
    expect(sent).toHaveLength(1);
    const [url, request] = sent[0] ?? ['', { method: 'GET' }];
    expect(url).toBe(RESEND_ENDPOINT);
    expect(request.method).toBe('POST');
    expect(request.headers?.['Authorization']).toBe('Bearer re_test');
    expect(JSON.parse(request.body ?? '{}')).toEqual({
      from: 'NestPrep <hello@nestprep.io>',
      to: ['sam@example.com'],
      subject: message.subject,
      text: message.text,
    });
  });

  it('posts the html beside the text when the message has one', async () => {
    const { http, sent } = recordingHttp(200);
    await resendEmailSender({ apiKey: 're_test', from: 'a@b.co' }, http).send({
      ...message,
      html: '<p>482913</p>',
    });
    const body = JSON.parse(sent[0]?.[1].body ?? '{}') as Record<string, unknown>;
    expect(body['html']).toBe('<p>482913</p>');
    expect(body['text']).toBe(message.text);
  });

  it('fails when Resend refuses, without saying who to', async () => {
    const { http } = recordingHttp(422);
    const failure = resendEmailSender({ apiKey: 're_test', from: 'a@b.co' }, http).send(message);
    await expect(failure).rejects.toThrow(EmailNotSent);
    await expect(failure).rejects.not.toThrow(/sam@example\.com/);
  });

  it('sends nothing while the key or the sender is not configured', async () => {
    for (const config of [
      { apiKey: null, from: 'a@b.co' },
      { apiKey: 're_test', from: null },
    ]) {
      const { http, sent } = recordingHttp(200);
      await expect(resendEmailSender(config, http).send(message)).rejects.toThrow(EmailNotSent);
      expect(sent).toHaveLength(0);
    }
  });
});
