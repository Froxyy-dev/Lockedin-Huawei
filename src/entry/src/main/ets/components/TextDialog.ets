import { HarmonyTheme } from '../theme/DesignTokens';

/**
 * Full-text reader: a card-styled dialog for text that is shown shortened elsewhere (the person's request, a change
 * request). Open it from any page:
 *
 *   private reader: CustomDialogController | null = null;
 *   private readFull(title: string, text: string): void {
 *     this.reader = new CustomDialogController({ builder: TextDialog({ title: title, text: text }), customStyle: true });
 *     this.reader.open();
 *   }
 */
@CustomDialog
export struct TextDialog {
  controller: CustomDialogController;
  title: string = '';
  text: string = '';

  build() {
    Column({ space: 14 }) {
      Text(this.title.toUpperCase()).fontSize(11).fontWeight(FontWeight.Bold)
        .letterSpacing(1.6).fontColor(HarmonyTheme.accent).width('100%')
      Scroll() {
        Text(this.text).fontSize(17).lineHeight(26).fontColor(HarmonyTheme.ink).width('100%')
      }
      .width('100%').constraintSize({ maxHeight: 460 }).scrollBar(BarState.Auto)
      Button('Close', { type: ButtonType.Normal })
        .id('TextDialogClose').backgroundColor(HarmonyTheme.softBlue).fontColor(HarmonyTheme.accent)
        .borderRadius(14).height(44).width('100%').fontWeight(FontWeight.Medium)
        .onClick(() => { this.controller.close(); })
    }
    .width('88%').padding(22).alignItems(HorizontalAlign.Start)
    .borderRadius(24).backgroundColor(Color.White).border({ width: 1, color: HarmonyTheme.border })
  }
}
