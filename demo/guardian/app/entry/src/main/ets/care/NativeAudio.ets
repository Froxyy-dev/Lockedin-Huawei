import { audio } from '@kit.AudioKit';
import { fileIo as fs } from '@kit.CoreFileKit';
import { hilog } from '@kit.PerformanceAnalysisKit';

export class NativeAudio {
  private capturer?: audio.AudioCapturer;
  private renderer?: audio.AudioRenderer;
  private queue: ArrayBuffer[] = [];
  private writing: boolean = false;
  private active: boolean = false;
  peak: number = 0;
  bytes: number = 0;
  private lastLog: number = 0;

  async start(onData: (buffer: ArrayBuffer) => void): Promise<void> {
    const stream: audio.AudioStreamInfo = {
      samplingRate: audio.AudioSamplingRate.SAMPLE_RATE_16000,
      channels: audio.AudioChannel.CHANNEL_1,
      sampleFormat: audio.AudioSampleFormat.SAMPLE_FORMAT_S16LE,
      encodingType: audio.AudioEncodingType.ENCODING_TYPE_RAW
    };
    this.renderer = await audio.createAudioRenderer({ streamInfo: stream,
      rendererInfo: { usage: audio.StreamUsage.STREAM_USAGE_VOICE_COMMUNICATION, rendererFlags: 0 } });
    await this.renderer.start();
    this.capturer = await audio.createAudioCapturer({ streamInfo: stream,
      capturerInfo: { source: audio.SourceType.SOURCE_TYPE_VOICE_COMMUNICATION, capturerFlags: 0 } });
    this.peak = 0; this.bytes = 0; this.active = true;
    this.capturer.on('readData', (buffer: ArrayBuffer): void => {
      const samples = new Int16Array(buffer);
      let peak: number = 0;
      for (let i = 0; i < samples.length; i++) { peak = Math.max(peak, Math.abs(samples[i])); }
      this.peak = Math.max(this.peak, peak); this.bytes += buffer.byteLength;
      if (Date.now() - this.lastLog > 1000) {
        this.lastLog = Date.now();
        hilog.info(0x0001, 'CareGuardian', 'MIC bytes=%{public}d peak=%{public}d', this.bytes, peak);
      }
      onData(buffer.slice(0));
    });
    await this.capturer.start();
  }

  play(buffer: ArrayBuffer): void {
    if (!this.active || !this.renderer) { return; }
    if (this.queue.length >= 100) { this.queue.shift(); }
    this.queue.push(buffer);
    if (!this.writing) { this.drain(); }
  }

  private async drain(): Promise<void> {
    this.writing = true;
    try {
      while (this.active && this.queue.length > 0 && this.renderer) {
        const buffer = this.queue.shift();
        if (buffer) {
          let offset: number = 0;
          while (offset < buffer.byteLength && this.active && this.renderer) {
            const written = await this.renderer.write(buffer.slice(offset));
            if (written <= 0) { break; }
            offset += written;
          }
        }
      }
    } catch (error) {
      hilog.error(0x0001, 'CareGuardian', 'Playback error %{public}s', JSON.stringify(error));
    } finally { this.writing = false; }
  }

  async echo(cacheDir: string, report: (message: string) => void): Promise<void> {
    let chunks: ArrayBuffer[] = [];
    await this.start((buffer: ArrayBuffer): void => { chunks.push(buffer); });
    report('Recording for 3 seconds — say something');
    await new Promise<void>((resolve: () => void): void => { setTimeout(resolve, 3000); });
    if (this.capturer) { await this.capturer.stop(); }
    const pcm = new Uint8Array(this.bytes);
    let offset: number = 0;
    chunks.forEach((chunk: ArrayBuffer): void => { pcm.set(new Uint8Array(chunk), offset); offset += chunk.byteLength; });
    const file = fs.openSync(cacheDir + '/care-microphone.pcm', fs.OpenMode.CREATE | fs.OpenMode.READ_WRITE | fs.OpenMode.TRUNC);
    fs.writeSync(file.fd, pcm.buffer); fs.closeSync(file);
    report('Playing your recording · peak ' + this.peak + ' · ' + this.bytes + ' bytes');
    hilog.info(0x0001, 'CareGuardian', 'ECHO peak=%{public}d bytes=%{public}d', this.peak, this.bytes);
    this.play(pcm.buffer as ArrayBuffer);
    await new Promise<void>((resolve: () => void): void => { setTimeout(resolve, 3500); });
    await this.stop();
    report('Audio check finished · peak ' + this.peak + '. Confirm that you heard your voice.');
  }

  interrupt(): void { this.queue = []; }

  async stop(): Promise<void> {
    this.active = false; this.queue = [];
    const cap = this.capturer; const render = this.renderer;
    this.capturer = undefined; this.renderer = undefined;
    if (cap) { try { await cap.stop(); } catch (error) {} await cap.release(); }
    if (render) { try { await render.stop(); } catch (error) {} await render.release(); }
  }
}
