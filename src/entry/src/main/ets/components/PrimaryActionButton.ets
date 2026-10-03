import { HarmonyTheme } from '../theme/DesignTokens';

@Component
export struct PrimaryActionButton {
  label: string = '';
  actionId: string = '';
  @Prop available: boolean = true;
  onAction: () => void = () => {};

  build() {
    Button(this.label, { type: ButtonType.Normal })
      .id(this.actionId)
      .width('100%')
      .height(56)
      .borderRadius(18)
      .backgroundColor(HarmonyTheme.accent)
      .fontColor(Color.White)
      .fontSize(18)
      .fontWeight(FontWeight.Medium)
      .enabled(this.available)
      .opacity(this.available ? 1 : 0.45)
      .stateEffect(true)
      .onClick(this.onAction)
  }
}
