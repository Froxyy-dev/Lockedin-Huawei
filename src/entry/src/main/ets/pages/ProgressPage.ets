import { router } from '@kit.ArkUI';
import { common } from '@kit.AbilityKit';
import { HarnessClient, ProgressEvent, ProgressFeed, describeError } from '../model/HarnessClient';
import { HarmonyTheme } from '../theme/DesignTokens';

export interface ProgressPageParams {
  projectId: string;
  n: number;
}

/** "14:32" from an ISO timestamp, in the phone's local time. */
function clock(iso: string): string {
  const d = new Date(iso);
  if (isNaN(d.getTime())) { return ''; }
  const h = d.getHours();
  const m = d.getMinutes();
  return (h < 10 ? '0' : '') + h + ':' + (m < 10 ? '0' : '') + m;
}

function headline(state: string): string {
  switch (state) {
    case 'building': return 'Your app is being built';
    case 'built': return 'Your app is ready';
    case 'failed': return 'The build did not finish';
    case 'cancelled': return 'The build was stopped';
    case 'drafted': return 'Not built yet';
    default: return state;
  }
}

@Component
struct ProgressRow {
  event: ProgressEvent = { t: '', last: '', kind: '', text: '', count: 1, problem: false };

  build() {
    Row({ space: 12 }) {
      Text(clock(this.event.t)).fontSize(12).fontColor(HarmonyTheme.secondary).width(42)
      Text(this.event.problem ? '!' : '•').fontSize(16).fontWeight(FontWeight.Bold)
        .fontColor(this.event.problem ? '#B42318' : HarmonyTheme.accent).width(14)
      Text(this.event.text + (this.event.count > 1 ? '  ×' + this.event.count : ''))
        .fontSize(15).lineHeight(21).fontColor(this.event.problem ? '#B42318' : HarmonyTheme.ink).layoutWeight(1)
    }.width('100%').alignItems(VerticalAlign.Top).padding({ top: 6, bottom: 6 })
  }
}

@Entry
@Component
struct ProgressPage {
  @State feed: ProgressFeed = { state: '', events: [] };
  @State loading: boolean = true;
  @State error: string = '';
  private projectId: string = '';
  private n: number = 0;
  private client?: HarnessClient;
  private generation: number = 0;
  private timers: number[] = [];

  aboutToAppear(): void {
    const params = router.getParams() as ProgressPageParams;
    this.projectId = params?.projectId ?? '';
    this.n = params?.n ?? 0;
    this.start();
  }

  aboutToDisappear(): void {
    this.stop();
  }

  private stop(): void {
    this.generation++;
    this.timers.forEach((t: number) => { clearTimeout(t); });
    this.timers = [];
  }

  private start(): void {
    this.stop();
    try {
      const context = this.getUIContext().getHostContext() as common.UIAbilityContext;
      this.client = new HarnessClient(HarnessClient.loadConfig(context));
    } catch (err) {
      this.error = 'Not configured: ' + describeError(err as Object);
      this.loading = false;
      return;
    }
    this.poll(this.generation);
  }

  /** Refresh every 3 s while the build runs; one read once it has ended. */
  private async poll(generation: number): Promise<void> {
    if (generation !== this.generation || !this.client) { return; }
    try {
      const feed = await this.client.progress(this.projectId, this.n);
      if (generation !== this.generation) { return; }
      this.feed = feed;
      this.error = '';
      if (feed.state === 'building') {
        this.timers.push(setTimeout(() => { this.poll(generation); }, 3000));
      }
    } catch (err) {
      if (generation === this.generation) {
        this.error = 'Could not load progress: ' + describeError(err as Object);
        this.timers.push(setTimeout(() => { this.poll(generation); }, 5000));
      }
    } finally {
      this.loading = false;
    }
  }

  build() {
    Column({ space: 0 }) {
      Row() {
        Button('‹', { type: ButtonType.Normal })
          .id('ProgressBack').backgroundColor(Color.Transparent).fontColor(HarmonyTheme.secondary)
          .fontSize(20).width(36).height(36).padding(0)
          .onClick(() => { router.back(); })
        Text('Progress · #' + this.n).fontSize(20).fontWeight(FontWeight.Bold)
          .fontColor(HarmonyTheme.ink).margin({ left: 6 })
      }.width('100%').alignItems(VerticalAlign.Center).margin({ bottom: 12 })

      if (this.error.length > 0) {
        Text(this.error).fontSize(13).fontColor('#B42318').width('100%').margin({ bottom: 8 })
      }

      if (this.loading) {
        LoadingProgress().width(36).height(36).color(HarmonyTheme.accent)
      } else {
        Row({ space: 10 }) {
          if (this.feed.state === 'building') {
            LoadingProgress().width(20).height(20).color(HarmonyTheme.accent)
          }
          Text(headline(this.feed.state)).id('ProgressHeadline').fontSize(16).fontWeight(FontWeight.Medium)
            .fontColor(HarmonyTheme.ink).layoutWeight(1)
        }.width('100%').padding(14).borderRadius(16).backgroundColor(Color.White)
        .border({ width: 1, color: HarmonyTheme.border }).margin({ bottom: 10 })

        if (this.feed.events.length === 0) {
          Text(this.feed.state === 'building' ? 'Waiting for the first news…' : 'Nothing has been built for this revision.')
            .fontSize(14).fontColor(HarmonyTheme.secondary).width('100%')
        } else {
          Scroll() {
            Column({ space: 0 }) {
              ForEach(this.feed.events, (event: ProgressEvent) => {
                ProgressRow({ event: event })
              }, (event: ProgressEvent, index: number) => index + ':' + event.last + ':' + event.count)
            }.width('100%').alignItems(HorizontalAlign.Start)
          }.layoutWeight(1).width('100%')
        }
      }
    }
    .width('100%').height('100%')
    .padding({ left: 24, right: 24, top: 18, bottom: 20 })
    .alignItems(HorizontalAlign.Start)
    .backgroundColor(HarmonyTheme.background)
  }
}
