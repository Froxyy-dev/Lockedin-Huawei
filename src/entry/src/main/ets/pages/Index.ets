import { common } from '@kit.AbilityKit';
import { router } from '@kit.ArkUI';
import { HarnessClient, Revision, describeError } from '../model/HarnessClient';
import { accessibility } from '@kit.AccessibilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { CreatePage } from '../components/CreatePage';
import { PlanningPage } from '../components/PlanningPage';
import { CareGuardianPlaceholder } from '../components/CareGuardianPlaceholder';
import { DEMO_PROMPT, ExperiencePlan, MockHarmonyPlanner } from '../model/HarmonyPlanner';
import { HarmonyTheme } from '../theme/DesignTokens';

@Entry
@Component
struct Index {
  @State prompt: string = DEMO_PROMPT;
  @State screen: string = 'create';
  @State stage: number = 0;
  @State plan: ExperiencePlan = new MockHarmonyPlanner().compose(DEMO_PROMPT);
  @State progress: string = '';
  @State error: string = '';
  @State ready: boolean = false;
  private generation: number = 0;
  private client?: HarnessClient;
  private projectId: string = '';
  private buildingRevision: number = 0;     // > 0 once accept went through
  private bundle: string = '';
  private controller: TextAreaController = new TextAreaController();
  private timers: number[] = [];
  private reduceMotion: boolean = false;

  aboutToAppear(): void {
    try {
      this.reduceMotion = accessibility.isAnimationReduceEnabledSync();
    } catch (_) {
      // API23+: older devices retain the restrained default animations.
      this.reduceMotion = false;
    }
  }

  aboutToDisappear(): void {
    this.cancelPlanning();
  }

  onBackPress(): boolean {
    if (this.screen !== 'create') {
      this.reset();
      return true;
    }
    return false;
  }

  private cancelPlanning(): void {
    this.generation++;
    this.timers.forEach((timer: number) => { clearTimeout(timer); });
    this.timers = [];
  }

  private reset(): void {
    this.cancelPlanning();
    this.screen = 'create';
    this.stage = 0;
    hilog.info(0x0001, 'HarmonyCreate', 'Demo reset');
  }

  /** One shot through the harness: idea -> planner spec (revision 1) -> accept -> build -> installed -> open. */
  private async beginPlanning(): Promise<void> {
    if (!this.prompt.trim()) { return; }
    this.cancelPlanning();
    const generation = this.generation;
    const text = this.prompt.trim();
    this.error = '';
    this.ready = false;
    this.progress = 'Designing the solution…';
    this.buildingRevision = 0;
    this.plan = { goal: text, experienceName: 'Your app', capabilities: [] };
    this.stage = 1;
    this.screen = 'planning';
    try {
      const context = this.getUIContext().getHostContext() as common.UIAbilityContext;
      this.client = new HarnessClient(HarnessClient.loadConfig(context));
      const project = await this.client.createProject(text.split(/\s+/).slice(0, 6).join(' '));
      this.projectId = project.id;
      const idea: Revision = await this.client.draft(project.id, text);
      if (generation !== this.generation) { return; }
      const title = idea.summary.title || 'Your app';
      this.plan = { goal: text, experienceName: title, capabilities: [] };
      hilog.info(0x0001, 'MissingApp', 'Project %{public}s spec ready: %{public}s', project.id, title);
      this.progress = 'Designed “' + title + '”. Starting the build…';
      await this.client.accept(project.id, idea.n);
      this.buildingRevision = idea.n;
      const detail = await this.client.project(project.id);
      this.bundle = detail.bundle ?? '';
      this.pollBuild(idea.n, title, generation, Date.now());
    } catch (err) {
      if (generation === this.generation) {
        this.error = 'Could not create your app: ' + describeError(err as Object);
        hilog.error(0x0001, 'MissingApp', 'Create failed: %{public}s', this.error);
      }
    }
  }

  private phaseText(phase: string | undefined, title: string): string {
    if (phase === undefined || phase === '' || phase === 'workspace' || phase === 'emulator') { return 'Preparing to build “' + title + '”…'; }
    if (phase === 'baseline') { return 'Preparing the native project…'; }
    if (phase.startsWith('agent')) { return 'Writing “' + title + '”…'; }
    if (phase.startsWith('repair')) { return 'Fixing build errors…'; }
    if (phase === 'verify') { return 'Building and checking your app…'; }
    return 'Building “' + title + '”…';
  }

  private async pollBuild(n: number, title: string, generation: number, started: number): Promise<void> {
    if (generation !== this.generation || !this.client) { return; }
    try {
      const rev: Revision = await this.client.revision(this.projectId, n);
      if (generation !== this.generation) { return; }
      if (rev.state === 'failed') { throw new Error(rev.error || 'The build failed'); }
      if (rev.state === 'cancelled') { throw new Error('The build was stopped on the server. Your request is kept: go back to try again.'); }
      if (rev.state === 'built') {
        this.progress = 'Installing your app…';
        this.ready = true;
        return;
      }
      const minutes = Math.floor((Date.now() - started) / 60000);
      this.progress = this.phaseText(rev.job?.phase, title) + (minutes > 0 ? '  (' + minutes + ' min)' : '');
      this.timers.push(setTimeout(() => { this.pollBuild(n, title, generation, started); }, 3000));
    } catch (err) {
      if (generation === this.generation) {
        this.error = describeError(err as Object);
        hilog.error(0x0001, 'MissingApp', 'Build failed: %{public}s', this.error);
      }
    }
  }

  /** Stop everything and go back to the prompt (kept as typed). A running build is stopped on the server, which
   *  restores the creation's last full revision. */
  private async cancelCreate(): Promise<void> {
    const n = this.buildingRevision;
    const client = this.client;
    this.reset();                                  // stops polling, back to the create screen with the same prompt
    this.buildingRevision = 0;
    if (n > 0 && client) {
      try {
        await client.cancel(this.projectId, n);
        hilog.info(0x0001, 'MissingApp', 'Cancelled build of %{public}s rev %{public}d', this.projectId, n);
      } catch (err) {
        hilog.error(0x0001, 'MissingApp', 'Cancel failed: %{public}s', describeError(err as Object));
      }
    }
  }

  /** The device agent installs a finished build within a few seconds; retry briefly instead of failing at once. */
  private async openGenerated(attempt: number = 0): Promise<void> {
    try {
      const context = this.getUIContext().getHostContext() as common.UIAbilityContext;
      await context.startAbility({ bundleName: this.bundle, abilityName: 'EntryAbility', moduleName: 'entry' });
      this.error = '';
    } catch (err) {
      if (attempt < 8) {
        this.timers.push(setTimeout(() => { this.openGenerated(attempt + 1); }, 2500));
      } else {
        this.error = 'Your app is built but not installed yet: ' + describeError(err as Object);
      }
    }
  }

  build() {
    Column() {
      Stack() {
        if (this.screen === 'create') {
          CreatePage({ prompt: $prompt, controller: this.controller, onCreate: () => { this.beginPlanning(); } })
            .transition(TransitionEffect.OPACITY.combine(TransitionEffect.scale({ x: 0.98, y: 0.98 })))
        } else if (this.screen === 'planning') {
          PlanningPage({ plan: this.plan, stage: this.stage, progress: this.progress, error: this.error, ready: this.ready, onBack: () => { this.reset(); },
            onOpen: () => { this.openGenerated(); }, onCancel: () => { this.cancelCreate(); } })
        } else {
          CareGuardianPlaceholder({ onBack: () => { this.reset(); } })
        }
      }
      .width('100%').layoutWeight(1)

      Button('Harness', { type: ButtonType.Normal })
        .id('OpenHarness')
        .backgroundColor(Color.Transparent)
        .fontColor(HarmonyTheme.secondary)
        .fontSize(12)
        .height(28)
        .onClick(() => { router.pushUrl({ url: 'pages/CreationsPage' }); })
    }
    .width('100%').height('100%').backgroundColor(HarmonyTheme.background)
  }
}
