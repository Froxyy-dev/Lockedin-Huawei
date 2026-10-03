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
    this.timers.forEach((timer: number) => { clearTimeout(timer); });
    this.timers = [];
  }

  private reset(): void {
    this.cancelPlanning();
    this.screen = 'create';
    this.stage = 0;
    hilog.info(0x0001, 'HarmonyCreate', 'Demo reset');
  }

  private beginPlanning(): void {
    if (!this.prompt.trim()) { return; }
    this.cancelPlanning();
    this.plan = new MockHarmonyPlanner().compose(this.prompt);
    this.stage = 0;
    this.getUIContext().animateTo({ duration: this.reduceMotion ? 0 : 180 }, () => {
      this.screen = 'planning';
    });
    const milestones: number[] = [500, 1000, 1400, 1800, 2200, 2600, 3500];
    milestones.forEach((delay: number, index: number) => {
      this.timers.push(setTimeout(() => {
        this.getUIContext().animateTo({ duration: this.reduceMotion ? 0 : 220, curve: Curve.EaseOut }, () => {
          this.stage = index + 1;
        });
        hilog.info(0x0001, 'HarmonyCreate', 'Mock planning stage %{public}d', index + 1);
      }, delay));
    });
  }

  build() {
    Stack() {
      if (this.screen === 'create') {
        CreatePage({ prompt: $prompt, controller: this.controller, onCreate: () => { this.beginPlanning(); } })
          .transition(TransitionEffect.OPACITY.combine(TransitionEffect.scale({ x: 0.98, y: 0.98 })))
      } else if (this.screen === 'planning') {
        PlanningPage({ plan: this.plan, stage: this.stage, onBack: () => { this.reset(); },
          onOpen: () => { this.screen = 'result'; } })
      } else {
        CareGuardianPlaceholder({ onBack: () => { this.reset(); } })
      }
    }
    .width('100%').height('100%').backgroundColor(HarmonyTheme.background)
  }
}
