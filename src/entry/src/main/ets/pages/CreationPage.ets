import { router } from '@kit.ArkUI';
import { common } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { HarnessClient, ProjectDetail, Revision, RevisionSummary, describeError } from '../model/HarnessClient';
import { HarmonyTheme } from '../theme/DesignTokens';
import { SpecPageParams } from './SpecPage';

interface CreationPageParams {
  projectId: string;
}

function toSummary(revision: Revision): RevisionSummary {
  return { n: revision.n, kind: revision.kind, state: revision.state, created: revision.created, summary: revision.summary };
}

@Component
struct RevisionChip {
  revision: RevisionSummary = { n: 0, kind: '', state: '', created: '', summary: { title: '', idea: '' } };
  @Prop selected: boolean = false;
  onTap: () => void = () => {};

  build() {
    Column({ space: 2 }) {
      Text('#' + this.revision.n).fontSize(13).fontWeight(FontWeight.Bold)
        .fontColor(this.selected ? Color.White : HarmonyTheme.ink)
      Text(this.revision.state).fontSize(11)
        .fontColor(this.selected ? Color.White : HarmonyTheme.secondary)
    }
    .padding({ left: 14, right: 14, top: 8, bottom: 8 })
    .borderRadius(14)
    .backgroundColor(this.selected ? HarmonyTheme.accent : '#EDF2F8')
    .onClick(this.onTap)
  }
}

@Entry
@Component
struct CreationPage {
  @State project: ProjectDetail | null = null;
  @State revisions: RevisionSummary[] = [];
  @State current: Revision | null = null;
  @State loading: boolean = true;
  @State error: string = '';
  @State draftPrompt: string = '';
  @State feedbackText: string = '';
  @State creatingDraft: boolean = false;
  @State refining: boolean = false;
  @State accepting: boolean = false;
  private projectId: string = '';
  private client?: HarnessClient;
  private generation: number = 0;
  private timers: number[] = [];

  aboutToAppear(): void {
    const params = router.getParams() as CreationPageParams;
    this.projectId = params?.projectId ?? '';
    this.loadProject();
  }

  aboutToDisappear(): void {
    this.cancelPolling();
  }

  private cancelPolling(): void {
    this.generation++;
    this.timers.forEach((t: number) => { clearTimeout(t); });
    this.timers = [];
  }

  private updateRevisionState(n: number, state: string): void {
    this.revisions = this.revisions.map((r: RevisionSummary): RevisionSummary => {
      if (r.n === n) {
        return { n: r.n, kind: r.kind, state: state, created: r.created, summary: r.summary };
      }
      return r;
    });
  }

  private async loadProject(): Promise<void> {
    this.loading = true;
    this.error = '';
    try {
      const context = this.getUIContext().getHostContext() as common.UIAbilityContext;
      const config = HarnessClient.loadConfig(context);
      this.client = new HarnessClient(config);
      const detail = await this.client.project(this.projectId);
      this.project = detail;
      this.revisions = detail.revisions;
      if (detail.revisions.length > 0) {
        await this.loadRevision(detail.current_revision);
      }
    } catch (err) {
      this.error = 'Could not load creation: ' + describeError(err);
      hilog.error(0x0001, 'Harness', 'load project failed: %{public}s', this.error);
    } finally {
      this.loading = false;
    }
  }

  private async loadRevision(n: number): Promise<void> {
    if (!this.client) { return; }
    try {
      const revision = await this.client.revision(this.projectId, n);
      this.current = revision;
      if (revision.state === 'building') {
        this.startPolling(n);
      } else {
        this.cancelPolling();
      }
    } catch (err) {
      this.error = 'Could not load revision: ' + describeError(err);
    }
  }

  private startPolling(n: number): void {
    this.cancelPolling();
    const generation = this.generation;
    this.poll(n, generation);
  }

  private async poll(n: number, generation: number): Promise<void> {
    if (generation !== this.generation || !this.client) { return; }
    try {
      const revision = await this.client.revision(this.projectId, n);
      if (generation !== this.generation) { return; }
      this.current = revision;
      this.updateRevisionState(n, revision.state);
      if (revision.state === 'built' || revision.state === 'failed') { return; }
      this.timers.push(setTimeout(() => { this.poll(n, generation); }, 3000));
    } catch (err) {
      if (generation === this.generation) {
        this.error = 'Build status check failed: ' + describeError(err);
      }
    }
  }

  private async createIdea(): Promise<void> {
    const text = this.draftPrompt.trim();
    if (!text || !this.client) { return; }
    this.creatingDraft = true;
    this.error = '';
    try {
      const revision = await this.client.draft(this.projectId, text);
      this.draftPrompt = '';
      this.revisions = [...this.revisions, toSummary(revision)];
      this.current = revision;
      if (this.project) {
        this.project.current_revision = revision.n;
      }
    } catch (err) {
      this.error = 'Could not create idea: ' + describeError(err);
    } finally {
      this.creatingDraft = false;
    }
  }

  private async suggestChanges(): Promise<void> {
    const feedback = this.feedbackText.trim();
    if (!feedback || !this.current || !this.client) { return; }
    this.refining = true;
    this.error = '';
    try {
      const revision = await this.client.refine(this.projectId, this.current.n, feedback);
      this.feedbackText = '';
      this.revisions = [...this.revisions, toSummary(revision)];
      this.current = revision;
      if (this.project) {
        this.project.current_revision = revision.n;
      }
    } catch (err) {
      this.error = 'Could not send changes: ' + describeError(err);
    } finally {
      this.refining = false;
    }
  }

  private async acceptAndBuild(): Promise<void> {
    if (!this.current || !this.client) { return; }
    this.accepting = true;
    this.error = '';
    try {
      const n = this.current.n;
      await this.client.accept(this.projectId, n);
      this.updateRevisionState(n, 'building');
      await this.loadRevision(n);
    } catch (err) {
      this.error = 'Could not start build: ' + describeError(err);
    } finally {
      this.accepting = false;
    }
  }

  private async openApp(): Promise<void> {
    if (!this.project || !this.project.bundle) {
      this.error = 'No app has been built for this creation yet.';
      return;
    }
    try {
      const context = this.getUIContext().getHostContext() as common.UIAbilityContext;
      await context.startAbility({ bundleName: this.project.bundle, abilityName: 'EntryAbility', moduleName: 'entry' });
    } catch (err) {
      this.error = 'Could not open app: ' + describeError(err);
    }
  }

  private openSpec(): void {
    if (!this.current) { return; }
    const params: SpecPageParams = { projectId: this.projectId, n: this.current.n };
    router.pushUrl({ url: 'pages/SpecPage', params: params });
  }

  build() {
    Scroll() {
      Column({ space: 16 }) {
        Row() {
          Button('‹', { type: ButtonType.Normal })
            .id('CreationBack').backgroundColor(Color.Transparent).fontColor(HarmonyTheme.secondary)
            .fontSize(20).width(36).height(36).padding(0)
            .onClick(() => { router.back(); })
          Text(this.project?.name ?? 'Creation').fontSize(24).fontWeight(FontWeight.Bold)
            .fontColor(HarmonyTheme.ink).margin({ left: 6 }).maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis })
        }.width('100%').alignItems(VerticalAlign.Center)

        if (this.error.length > 0) {
          Text(this.error).fontSize(13).fontColor('#B42318').width('100%')
        }

        if (this.loading) {
          LoadingProgress().width(36).height(36).color(HarmonyTheme.accent)
        } else {
          if (this.revisions.length > 0) {
            Scroll() {
              Row({ space: 8 }) {
                ForEach(this.revisions, (revision: RevisionSummary) => {
                  RevisionChip({
                    revision: revision,
                    selected: this.current?.n === revision.n,
                    onTap: () => { this.cancelPolling(); this.loadRevision(revision.n); }
                  })
                }, (revision: RevisionSummary) => String(revision.n))
              }
            }.scrollable(ScrollDirection.Horizontal).width('100%')
          }

          if (this.revisions.length === 0) {
            Column({ space: 10 }) {
              Text('Describe the app you want to create').fontSize(15).fontWeight(FontWeight.Medium)
                .fontColor(HarmonyTheme.ink)
              TextArea({ text: this.draftPrompt, placeholder: 'What should this app do?' })
                .id('IdeaPrompt')
                .height(100).fontSize(15).backgroundColor('#EDF2F8').borderRadius(14)
                .onChange((value: string) => { this.draftPrompt = value; })
              if (this.creatingDraft) {
                Row({ space: 10 }) {
                  LoadingProgress().width(22).height(22).color(HarmonyTheme.accent)
                  Text('Thinking… ~20 s').fontSize(14).fontColor(HarmonyTheme.secondary)
                }
              } else {
                Button('Create idea', { type: ButtonType.Normal })
                  .id('CreateIdea').backgroundColor(HarmonyTheme.accent).fontColor(Color.White)
                  .borderRadius(14).height(48).width('100%')
                  .enabled(this.draftPrompt.trim().length > 0)
                  .onClick(() => { this.createIdea(); })
              }
            }.width('100%').alignItems(HorizontalAlign.Start)
          } else if (this.current) {
            Column({ space: 10 }) {
              Text(this.current.summary.title || 'Untitled').fontSize(21).fontWeight(FontWeight.Bold)
                .fontColor(HarmonyTheme.ink)
              Text(this.current.summary.idea).fontSize(14).lineHeight(20).fontColor(HarmonyTheme.secondary)
            }
            .width('100%').alignItems(HorizontalAlign.Start).padding(18)
            .borderRadius(20).backgroundColor(Color.White).border({ width: 1, color: HarmonyTheme.border })

            Button('Full spec', { type: ButtonType.Normal })
              .id('FullSpecButton').backgroundColor(HarmonyTheme.softBlue).fontColor(HarmonyTheme.accent)
              .borderRadius(14).height(46).width('100%').fontWeight(FontWeight.Medium)
              .onClick(() => { this.openSpec(); })

            if (this.current.state === 'building') {
              Row({ space: 10 }) {
                LoadingProgress().width(22).height(22).color(HarmonyTheme.accent)
                Text('Building… ' + (this.current.job?.phase ?? this.current.state))
                  .fontSize(14).fontColor(HarmonyTheme.secondary)
              }.width('100%')
            } else if (this.current.state === 'built') {
              Button('Open app', { type: ButtonType.Normal })
                .id('OpenApp').backgroundColor(HarmonyTheme.accent).fontColor(Color.White)
                .borderRadius(14).height(48).width('100%')
                .onClick(() => { this.openApp(); })
            } else if (this.current.state === 'failed') {
              Text('Build failed: ' + (this.current.error ?? 'unknown error'))
                .fontSize(13).fontColor('#B42318').width('100%')
            } else {
              Button(this.accepting ? 'Starting…' : 'Accept & build', { type: ButtonType.Normal })
                .id('AcceptBuild').backgroundColor(HarmonyTheme.accent).fontColor(Color.White)
                .borderRadius(14).height(48).width('100%')
                .enabled(!this.accepting)
                .onClick(() => { this.acceptAndBuild(); })
            }

            Column({ space: 8 }) {
              Text('Suggest changes').fontSize(14).fontWeight(FontWeight.Medium).fontColor(HarmonyTheme.ink)
              TextArea({ text: this.feedbackText, placeholder: 'What should change?' })
                .id('FeedbackPrompt')
                .height(80).fontSize(14).backgroundColor('#EDF2F8').borderRadius(14)
                .onChange((value: string) => { this.feedbackText = value; })
              Button(this.refining ? 'Sending…' : 'Send', { type: ButtonType.Normal })
                .id('SendFeedback').backgroundColor(HarmonyTheme.softBlue).fontColor(HarmonyTheme.accent)
                .borderRadius(14).height(44).width('100%')
                .enabled(this.feedbackText.trim().length > 0 && !this.refining)
                .onClick(() => { this.suggestChanges(); })
            }.width('100%').alignItems(HorizontalAlign.Start).margin({ top: 8 })
          }
        }
      }
      .width('100%')
      .alignItems(HorizontalAlign.Start)
      .padding({ left: 24, right: 24, top: 18, bottom: 28 })
    }
    .width('100%').height('100%')
    .backgroundColor(HarmonyTheme.background)
  }
}
