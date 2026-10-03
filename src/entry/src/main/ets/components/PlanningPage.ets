import { Capability, ExperiencePlan, MockHarmonyPlanner, DEMO_PROMPT } from '../model/HarmonyPlanner';
import { HarmonyTheme } from '../theme/DesignTokens';
import { PrimaryActionButton } from './PrimaryActionButton';

@Component
struct GoalCard {
  goal: string = '';

  build() {
    Column({ space: 12 }) {
      Text('YOUR REQUEST').fontSize(11).fontWeight(FontWeight.Bold)
        .letterSpacing(1.6).fontColor(HarmonyTheme.accent)
      Text(this.goal).fontSize(25).lineHeight(32).fontWeight(FontWeight.Medium)
        .fontColor(HarmonyTheme.ink).maxLines(2).textOverflow({ overflow: TextOverflow.Ellipsis })
    }
    .width('100%').alignItems(HorizontalAlign.Start).padding(22)
    .borderRadius(24).backgroundColor(Color.White)
    .border({ width: 1, color: HarmonyTheme.border })
  }
}

@Component
struct CapabilitySelectionRow {
  capability: Capability = { name: '', icon: $r('app.media.cap_watch') };
  @Prop selected: boolean = false;

  build() {
    Row({ space: 12 }) {
      Image(this.capability.icon).width(20).height(20).accessibilityLevel('no')
      Text(this.capability.name).fontSize(17).fontColor(HarmonyTheme.ink).layoutWeight(1)
      Text(this.selected ? '✓' : '·').fontSize(20).fontColor(this.selected ? HarmonyTheme.accent : '#A4B2C6')
    }
    .height(44).width('100%').padding({ left: 4, right: 4 })
    .opacity(this.selected ? 1 : 0)
    .translate({ y: this.selected ? 0 : 5 })
  }
}

@Component
export struct PlanningPage {
  plan: ExperiencePlan = new MockHarmonyPlanner().compose(DEMO_PROMPT);
  @Prop progress: string = '';
  @Prop error: string = '';
  @Prop ready: boolean = false;
  @Prop stage: number = 0;
  onBack: () => void = () => {};
  onOpen: () => void = () => {};

  build() {
    Column() {
      Button('‹  The Missing App', { type: ButtonType.Normal })
        .id('PlanningBack').backgroundColor(Color.Transparent).fontColor(HarmonyTheme.secondary)
        .fontSize(14).height(36).padding(0).onClick(this.onBack)
      Text('Understanding your need…').fontSize(30).lineHeight(36)
        .fontWeight(FontWeight.Bold).fontColor(HarmonyTheme.ink).width('100%').margin({ top: 22 })
      GoalCard({ goal: this.plan.goal }).margin({ top: 24 })
        .opacity(this.stage >= 1 ? 1 : 0).translate({ y: this.stage >= 1 ? 0 : 10 })
      Text('Creating a native HarmonyOS app').fontSize(15).fontWeight(FontWeight.Medium)
        .fontColor(HarmonyTheme.secondary).margin({ top: 24, bottom: 10 })
        .opacity(this.stage >= 1 ? 1 : 0)
      ForEach(this.plan.capabilities, (item: Capability, index: number) => {
        CapabilitySelectionRow({ capability: item, selected: this.stage >= index + 2 })
      }, (item: Capability) => item.name)
      Blank().layoutWeight(1)
      if (this.ready) {
        Text('Your app is ready').fontSize(14).fontColor(HarmonyTheme.secondary).margin({ bottom: 12 })
        PrimaryActionButton({ label: 'Open your app', actionId: 'OpenCareGuardian', onAction: this.onOpen })
      } else {
        Text(this.error || this.progress)
          .fontSize(16).fontColor(this.error ? '#B42318' : HarmonyTheme.secondary).width('100%').height(100)
      }
    }
    .width('100%').height('100%').alignItems(HorizontalAlign.Start)
    .padding({ left: 24, right: 24, top: 10, bottom: 24 })
  }
}
