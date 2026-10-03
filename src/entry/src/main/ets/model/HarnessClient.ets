import { http } from '@kit.NetworkKit';
import { common } from '@kit.AbilityKit';
import { util } from '@kit.ArkTS';

export interface HarnessConfig {
  baseUrl: string;
  token: string;
}

interface BotFallbackConfig {
  baseUrl: string;
  token: string;
}

export interface Me {
  client_id: string;
}

export interface Project {
  id: string;
  name: string;
  created: string;
  current_revision: number;
  latest_state: string;
}

export interface ProjectDetail {
  id: string;
  name: string;
  created: string;
  current_revision: number;
  bundle?: string;
  revisions: RevisionSummary[];
}

export interface RevisionSummaryInfo {
  title: string;
  idea: string;
}

export interface RevisionSummary {
  n: number;
  kind: string;
  state: string;
  created: string;
  summary: RevisionSummaryInfo;
}

export interface RevisionRequest {
  kind: string;
  text: string;
  based_on: number | null;
  created: string;
}

export interface RevisionJob {
  id: string;
  status: string;
  phase?: string;
}

export interface Revision {
  n: number;
  kind: string;
  state: string;
  created: string;
  summary: RevisionSummaryInfo;
  request?: RevisionRequest;
  job?: RevisionJob;
  error?: string;
}

export interface AcceptResult {
  job_id: string;
}

export interface DiffResult {
  stat: string;
  patch: string;
}

interface CreateProjectRequest {
  name: string;
}

interface DraftRequest {
  text: string;
}

interface RefineRequest {
  feedback: string;
}

function withPort(baseUrl: string, port: number): string {
  return baseUrl.replace(/:\d+$/, ':' + port);
}

export class HarnessClient {
  private config: HarnessConfig;

  constructor(config: HarnessConfig) {
    this.config = config;
  }

  static loadConfig(context: common.UIAbilityContext): HarnessConfig {
    try {
      const content = context.resourceManager.getRawFileContentSync('harness.json');
      const text = util.TextDecoder.create('utf-8').decodeToString(content);
      return JSON.parse(text) as HarnessConfig;
    } catch (_) {
      const fallbackContent = context.resourceManager.getRawFileContentSync('bot.json');
      const fallbackText = util.TextDecoder.create('utf-8').decodeToString(fallbackContent);
      const fallback = JSON.parse(fallbackText) as BotFallbackConfig;
      return { baseUrl: withPort(fallback.baseUrl, 8788), token: fallback.token };
    }
  }

  private async request(path: string, method: http.RequestMethod, body?: string): Promise<string> {
    const req = http.createHttp();
    try {
      const headers: Record<string, string> = {
        'Authorization': 'Bearer ' + this.config.token,
        'Content-Type': 'application/json'
      };
      const response = await req.request(this.config.baseUrl + path, {
        method: method,
        header: headers,
        extraData: body ?? '',
        connectTimeout: 10000,
        readTimeout: 40000
      });
      if (response.responseCode < 200 || response.responseCode >= 300) {
        throw new Error('Server returned HTTP ' + response.responseCode);
      }
      return response.result as string;
    } finally {
      req.destroy();
    }
  }

  async me(): Promise<Me> {
    return JSON.parse(await this.request('/me', http.RequestMethod.GET)) as Me;
  }

  async projects(): Promise<Project[]> {
    return JSON.parse(await this.request('/projects', http.RequestMethod.GET)) as Project[];
  }

  async createProject(name: string): Promise<Project> {
    const body: CreateProjectRequest = { name: name };
    return JSON.parse(await this.request('/projects', http.RequestMethod.POST, JSON.stringify(body))) as Project;
  }

  async project(id: string): Promise<ProjectDetail> {
    return JSON.parse(await this.request('/projects/' + id, http.RequestMethod.GET)) as ProjectDetail;
  }

  async draft(id: string, text: string): Promise<Revision> {
    const body: DraftRequest = { text: text };
    return JSON.parse(await this.request('/projects/' + id + '/revisions', http.RequestMethod.POST, JSON.stringify(body))) as Revision;
  }

  async refine(id: string, n: number, feedback: string): Promise<Revision> {
    const body: RefineRequest = { feedback: feedback };
    return JSON.parse(await this.request('/projects/' + id + '/revisions/' + n + '/refine', http.RequestMethod.POST, JSON.stringify(body))) as Revision;
  }

  async revision(id: string, n: number): Promise<Revision> {
    return JSON.parse(await this.request('/projects/' + id + '/revisions/' + n, http.RequestMethod.GET)) as Revision;
  }

  async spec(id: string, n: number): Promise<string> {
    return await this.request('/projects/' + id + '/revisions/' + n + '/spec', http.RequestMethod.GET);
  }

  async accept(id: string, n: number): Promise<AcceptResult> {
    return JSON.parse(await this.request('/projects/' + id + '/revisions/' + n + '/accept', http.RequestMethod.POST, '')) as AcceptResult;
  }

  async diff(id: string, n: number): Promise<DiffResult> {
    return JSON.parse(await this.request('/projects/' + id + '/revisions/' + n + '/diff', http.RequestMethod.GET)) as DiffResult;
  }
}
