import { common } from '@kit.AbilityKit';
import { util } from '@kit.ArkTS';
import { router } from '@kit.ArkUI';
import { BotClient, BotConfig, BotJob } from '../model/BotClient';
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
  private client?: BotClient;
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

  private async beginPlanning(): Promise<void> {
    if (!this.prompt.trim()) { return; }
    this.cancelPlanning();
    const generation = this.generation;
    this.error = '';
    this.ready = false;
    this.progress = 'Sending your request…';
    this.plan = { goal: this.prompt.trim(), experienceName: 'Your app', capabilities: [] };
    this.stage = 1;
    this.screen = 'planning';
    try {
      const context = this.getUIContext().getHostContext() as common.UIAbilityContext;
      const content = context.resourceManager.getRawFileContentSync('bot.json');
      const config = JSON.parse(util.TextDecoder.create('utf-8').decodeToString(content)) as BotConfig;
      this.client = new BotClient(config);
      const submitted = await this.client.submit(this.prompt);
      if (generation !== this.generation) { return; }
      hilog.info(0x0001, 'MissingApp', 'Submitted job %{public}s', submitted.id);
      this.progress = 'Request received. Waiting for generator…';
      this.pollJob(submitted.id, generation, Date.now());
    } catch (err) {
      if (generation === this.generation) {
        this.error = 'Could not send request. Check the local server and connection.';
        hilog.error(0x0001, 'MissingApp', 'Submit failed: %{public}s', String(err));
      }
    }
  }

  private async pollJob(id: string, generation: number, started: number): Promise<void> {
    if (generation !== this.generation || !this.client) { return; }
    try {
      const job: BotJob = await this.client.job(id);
      if (generation !== this.generation) { return; }
      if (job.status === 'failed') { throw new Error(job.error || 'Generation failed'); }
      if (job.deployed && !job.deployed.ok) { throw new Error('Installation failed: ' + job.deployed.detail); }
      if (job.status === 'succeeded' && job.deployed && job.deployed.ok) {
        this.ready = true;
        this.progress = 'Your app is installed and ready';
        return;
      }
      this.progress = job.status === 'succeeded' ? 'Installing your app…' :
        job.phase === 'baseline' ? 'Preparing the native project…' :
        job.phase === 'agent:codex' ? 'Codex is creating your app…' :
        job.phase === 'verify' ? 'Building and checking your app…' : 'Waiting for generator…';
      if (Date.now() - started > 600000) { throw new Error('Timed out waiting for generator'); }
      this.timers.push(setTimeout(() => { this.pollJob(id, generation, started); }, 2500));
    } catch (err) {
      if (generation === this.generation) {
        this.error = String(err);
        hilog.error(0x0001, 'MissingApp', 'Job failed: %{public}s', this.error);
      }
    }
  }

  private async openGenerated(): Promise<void> {
    try {
      const context = this.getUIContext().getHostContext() as common.UIAbilityContext;
      await context.startAbility({ bundleName: 'com.hackyeah.generated', abilityName: 'EntryAbility', moduleName: 'entry' });
    } catch (err) {
      this.error = 'Could not open generated app: ' + String(err);
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
            onOpen: () => { this.openGenerated(); } })
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
