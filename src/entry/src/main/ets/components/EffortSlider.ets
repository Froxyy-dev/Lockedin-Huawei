import { EFFORT_LEVELS } from '../model/HarnessClient';
import { HarmonyTheme } from '../theme/DesignTokens';

/** fast · medium · high. One position sets how hard the planner and the engineer think, and their pace. */
@Component
export struct EffortSlider {
  @Link effort: string;
  interactive: boolean = true;   // not 'enabled': that name collides with the ArkUI attribute

  private index(): number {
    const i = EFFORT_LEVELS.indexOf(this.effort);
    return i < 0 ? 1 : i;
  }

  build() {
    Column({ space: 4 }) {
      Row() {
        Text('Effort').fontSize(13).fontWeight(FontWeight.Medium).fontColor(HarmonyTheme.secondary).layoutWeight(1)
        Text(this.effort).id('EffortLabel').fontSize(13).fontWeight(FontWeight.Bold).fontColor(HarmonyTheme.accent)
      }.width('100%')
      Slider({ value: this.index(), min: 0, max: 2, step: 1, style: SliderStyle.OutSet })
        .id('EffortSlider')
        .showSteps(true)
        .selectedColor(HarmonyTheme.accent)
        .trackColor('#D5DEEA')
        .enabled(this.interactive)
        .onChange((value: number) => { this.effort = EFFORT_LEVELS[Math.round(value)] ?? 'medium'; })
      Row() {
        Text('fast').fontSize(11).fontColor(HarmonyTheme.secondary).layoutWeight(1)
        Text('medium').fontSize(11).fontColor(HarmonyTheme.secondary).layoutWeight(1).textAlign(TextAlign.Center)
        Text('high').fontSize(11).fontColor(HarmonyTheme.secondary).layoutWeight(1).textAlign(TextAlign.End)
      }.width('100%')
    }.width('100%').alignItems(HorizontalAlign.Start)
  }
}
