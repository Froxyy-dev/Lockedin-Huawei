import { AVAILABLE_CAPABILITIES } from '../model/HarmonyPlanner';
import { HarmonyTheme } from '../theme/DesignTokens';
import { PromptCard } from './PromptCard';
import { CapabilityChip } from './CapabilityChip';
import { PrimaryActionButton } from './PrimaryActionButton';

@Component
export struct CreatePage {
  @Link prompt: string;
  controller: TextAreaController = new TextAreaController();
  onCreate: () => void = () => {};

  build() {
    Column() {
      Column({ space: 5 }) {
        Text('Harmony Create').fontSize(19).fontWeight(FontWeight.Medium).fontColor(HarmonyTheme.ink)
        Text('Personal software, just in time.').fontSize(13).fontColor(HarmonyTheme.secondary)
      }.width('100%').alignItems(HorizontalAlign.Start)
      Text('What should your device help you with?')
        .fontSize(34).fontWeight(FontWeight.Bold).fontColor(HarmonyTheme.ink)
        .lineHeight(40).width('100%').margin({ top: 28, bottom: 22 })
      PromptCard({ prompt: $prompt, controller: this.controller })
      Column({ space: 10 }) {
        Text('Harmony can use').fontSize(13).fontWeight(FontWeight.Medium).fontColor(HarmonyTheme.secondary)
        Row({ space: 8 }) {
          CapabilityChip({ capability: AVAILABLE_CAPABILITIES[0] })
          CapabilityChip({ capability: AVAILABLE_CAPABILITIES[1] })
          CapabilityChip({ capability: AVAILABLE_CAPABILITIES[2] })
        }.width('100%')
        Row({ space: 8 }) {
          CapabilityChip({ capability: AVAILABLE_CAPABILITIES[3] })
          CapabilityChip({ capability: AVAILABLE_CAPABILITIES[4] })
          CapabilityChip({ capability: AVAILABLE_CAPABILITIES[5] })
        }.width('100%')
      }.width('100%').alignItems(HorizontalAlign.Start).margin({ top: 20 })
      Blank().layoutWeight(1)
      PrimaryActionButton({ label: '✦ Create with Harmony', actionId: 'CreateHarmony',
        available: this.prompt.trim().length > 0, onAction: () => {
          this.controller.stopEditing();
          this.onCreate();
        } })
      Text('You describe the need. Harmony designs the experience.')
        .fontSize(12).fontColor(HarmonyTheme.secondary).textAlign(TextAlign.Center).width('100%')
        .lineHeight(18).margin({ top: 12 })
    }
    .width('100%').height('100%')
    .padding({ left: 24, right: 24, top: 18, bottom: 20 })
    .alignItems(HorizontalAlign.Start)
  }
}
