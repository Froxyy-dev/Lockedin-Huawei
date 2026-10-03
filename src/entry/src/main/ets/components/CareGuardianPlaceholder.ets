import { HarmonyTheme } from '../theme/DesignTokens';
import { PrimaryActionButton } from './PrimaryActionButton';

@Component
export struct CareGuardianPlaceholder {
  onBack: () => void = () => {};

  build() {
    Column() {
      Button('‹  Harmony Create', { type: ButtonType.Normal })
        .id('ResultBack').backgroundColor(Color.Transparent).fontColor(HarmonyTheme.secondary)
        .fontSize(14).height(36).padding(0).alignSelf(ItemAlign.Start).onClick(this.onBack)
      Blank().layoutWeight(1)
      Row() {
        Image($r('app.media.cap_health')).width(40).height(40)
      }.width(96).height(96).justifyContent(FlexAlign.Center)
        .backgroundColor(HarmonyTheme.softBlue).borderRadius(32)
      Text('Care Guardian').fontSize(36).fontWeight(FontWeight.Bold)
        .fontColor(HarmonyTheme.ink).margin({ top: 24, bottom: 10 })
      Text('Experience ready').fontSize(18).fontColor(HarmonyTheme.secondary)
      Blank().layoutWeight(1)
      PrimaryActionButton({ label: 'Back to Harmony Create', actionId: 'ResetDemo', onAction: this.onBack })
    }.width('100%').height('100%').padding({ left: 24, right: 24, top: 10, bottom: 24 })
  }
}
