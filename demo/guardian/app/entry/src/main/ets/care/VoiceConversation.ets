import { http, webSocket } from '@kit.NetworkKit';
import { util } from '@kit.ArkTS';
import { common } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { NativeAudio } from './NativeAudio';
import { currentLocation, CareLocation } from './LocationProvider';

export interface CareConfig { appId: string; token: string; runtimeUrl: string; name: string; audioSource: string; }
interface SessionResponse { id: string; wsPath: string; }
interface AudioEvent { audio_base_64: string; }
interface TranscriptEvent { user_transcript: string; }
interface ResponseEvent { agent_response: string; }
interface CallResult { state: string; error: string; }
interface CareEvent {
  type: string;
  audio_event?: AudioEvent;
  user_transcription_event?: TranscriptEvent;
  agent_response_event?: ResponseEvent;
  result?: CallResult;
  message?: string;
}

export class VoiceConversation {
  private socket?: webSocket.WebSocket;
  private audio: NativeAudio = new NativeAudio();
  private config?: CareConfig;
  private sessionId: string = '';
  private active: boolean = false;
  private callFinished: boolean = false;
  private codec: util.Base64Helper = new util.Base64Helper();

  private async post(path: string, body: string): Promise<string> {
    if (!this.config) { throw new Error('Runtime config missing'); }
    const request = http.createHttp();
    try {
      const response = await request.request(this.config.runtimeUrl + path, {
        method: http.RequestMethod.POST, header: { 'Authorization': 'Bearer ' + this.config.token, 'Content-Type': 'application/json' },
        extraData: body, connectTimeout: 10000, readTimeout: 15000
      });
      if (response.responseCode >= 300) { throw new Error('Runtime HTTP ' + response.responseCode); }
      return response.result as string;
    } finally { request.destroy(); }
  }

  async start(config: CareConfig, context: common.UIAbilityContext, laptop: boolean,
    status: (message: string) => void, transcript: (message: string) => void): Promise<void> {
    this.config = config; this.active = true; this.callFinished = false;
    status('Connecting to Care Guardian…');
    const response = JSON.parse(await this.post('/sessions', JSON.stringify({ appId: config.appId }))) as SessionResponse;
    if (!this.active) { return; }
    this.sessionId = response.id;
    const socket = webSocket.createWebSocket(); this.socket = socket;
    socket.on('message', (error: BusinessError, value: string | ArrayBuffer): void => {
      if (error || typeof value !== 'string') { return; }
      const event = JSON.parse(value) as CareEvent;
      if (event.type === 'audio' && event.audio_event) {
        status('Care Guardian is speaking');
        if (!laptop) { this.audio.play(this.codec.decodeSync(event.audio_event.audio_base_64).buffer as ArrayBuffer); }
      } else if (event.type === 'user_transcript' && event.user_transcription_event) {
        transcript('You: ' + event.user_transcription_event.user_transcript); status('Listening');
      } else if (event.type === 'agent_response' && event.agent_response_event) {
        transcript('Care Guardian: ' + event.agent_response_event.agent_response);
      } else if (event.type === 'interruption') { this.audio.interrupt(); status('Listening');
      } else if (event.type === 'care_silence_escalation') {
        status('No response · contacting caregiver…');
      } else if (event.type === 'care_location_request') {
        status('Getting location…');
        currentLocation(context).then((location: CareLocation): void => {
          this.post('/sessions/' + this.sessionId + '/location', JSON.stringify(location)).catch((error: Error): void => { status(error.message); });
        });
      } else if (event.type === 'care_call_result' && event.result) {
        this.callFinished = true;
        status(event.result.state === 'submitted' ? 'Mateusz is being contacted' : 'Call failed: ' + event.result.error);
      } else if (event.type === 'care_error') { status('Error: ' + event.message); this.stop(); }
      hilog.info(0x0001, 'CareGuardian', 'EVENT %{public}s', event.type);
    });
    socket.on('error', (error: BusinessError): void => { status('Connection error ' + error.code); this.stop(); });
    socket.on('close', (): void => { this.audio.stop(); if (this.active) { this.active = false; if (!this.callFinished) { status('Session ended — tap Reset to try again'); } } });
    await socket.connect(config.runtimeUrl.replace('http', 'ws') + response.wsPath + (laptop ? '?source=laptop' : ''),
      { header: { 'Authorization': 'Bearer ' + config.token } });
    if (!laptop) {
      await this.audio.start((buffer: ArrayBuffer): void => {
        if (this.active && this.socket) {
          this.socket.send(JSON.stringify({ user_audio_chunk: this.codec.encodeToStringSync(new Uint8Array(buffer)) })).catch((error: BusinessError): void => {});
        }
      });
    }
    status(laptop ? 'Listening · laptop audio bridge' : 'Listening · native microphone');
  }

  async stop(): Promise<void> {
    this.active = false;
    const socket = this.socket; this.socket = undefined;
    if (socket) { try { await socket.send(JSON.stringify({ type: 'care_end' })); await socket.close(); } catch (error) {} }
    await this.audio.stop();
  }
}
