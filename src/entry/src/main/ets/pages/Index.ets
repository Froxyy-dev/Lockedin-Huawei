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

interface CreationPageParams {
  projectId: string;
}

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

  /** Create: idea -> planner spec (revision 1) -> the creation page to read, refine or accept and build. */
  private async beginPlanning(): Promise<void> {
    if (!this.prompt.trim()) { return; }
    this.cancelPlanning();
    const generation = this.generation;
    const text = this.prompt.trim();
    this.error = '';
    this.ready = false;
    this.progress = 'Designing the solution…';
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
      // The plan's review step: the person reads the summary, refines or accepts. Nothing builds before that.
      this.reset();
      router.pushUrl({ url: 'pages/CreationPage', params: { projectId: project.id } as CreationPageParams });
    } catch (err) {
      if (generation === this.generation) {
        this.error = 'Could not create your app: ' + describeError(err as Object);
        hilog.error(0x0001, 'MissingApp', 'Create failed: %{public}s', this.error);
      }
    }
  }

  /** Cancel while the solution is being designed: back to the prompt, kept as typed. (Builds are cancelled on the
   *  creation page, where they are started.) */
  private cancelCreate(): void {
    this.reset();
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
