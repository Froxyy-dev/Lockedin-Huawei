import { http } from '@kit.NetworkKit';

export interface BotConfig {
  baseUrl: string;
  token: string;
}

interface JobRequest {
  prompt: string;
  name: string;
}

export interface Submission {
  id: string;
}

export interface Deployment {
  ok: boolean;
  detail: string;
}

export interface BotJob {
  id: string;
  status: string;
  phase: string;
  error?: string;
  deployed?: Deployment;
}

export class BotClient {
  private config: BotConfig;

  constructor(config: BotConfig) { this.config = config; }

  private async request(path: string, body?: string): Promise<string> {
    const req = http.createHttp();
    try {
      const headers: Record<string, string> = {
        'Authorization': 'Bearer ' + this.config.token,
        'Content-Type': 'application/json'
      };
      const response = await req.request(this.config.baseUrl + path, {
        method: body ? http.RequestMethod.POST : http.RequestMethod.GET,
        header: headers, extraData: body || '', connectTimeout: 10000, readTimeout: 20000
      });
      if (response.responseCode < 200 || response.responseCode >= 300) {
        throw new Error('Server returned HTTP ' + response.responseCode);
      }
      return response.result as string;
    } finally { req.destroy(); }
  }

  async submit(prompt: string): Promise<Submission> {
    const body: JobRequest = { prompt: prompt, name: 'The Missing App' };
    return JSON.parse(await this.request('/jobs', JSON.stringify(body))) as Submission;
  }

  async job(id: string): Promise<BotJob> {
    return JSON.parse(await this.request('/jobs/' + id)) as BotJob;
  }
}
