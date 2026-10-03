import { Capability } from '../model/HarmonyPlanner';
import { HarmonyTheme } from '../theme/DesignTokens';

@Component
export struct CapabilityChip {
  capability: Capability = { name: '', icon: $r('app.media.cap_watch') };

  build() {
    Row({ space: 6 }) {
      Image(this.capability.icon).width(16).height(16).accessibilityLevel('no')
      Text(this.capability.name).fontSize(13).fontColor(HarmonyTheme.secondary)
    }
    .padding({ left: 10, right: 10, top: 8, bottom: 8 })
    .backgroundColor('#EDF2F8')
    .borderRadius(12)
  }
}
