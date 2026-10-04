import { ProgressEvent } from '../model/HarnessClient';
import { HarmonyTheme } from '../theme/DesignTokens';

/** The "(doing x)" card for every wait: designing, considering feedback, building. Headline + the last feed lines. */
@Component
export struct WaitCard {
  @Prop headline: string = '';
  @Prop events: ProgressEvent[] = [];
  @Prop quietNote: string = '';
  showCancel: boolean = false;
  cancelling: boolean = false;
  onCancel: () => void = () => {};

  build() {
    Column({ space: 8 }) {
      Row({ space: 10 }) {
        LoadingProgress().width(22).height(22).color(HarmonyTheme.accent)
        Text(this.headline).id('WaitHeadline').fontSize(15).fontWeight(FontWeight.Medium)
          .fontColor(HarmonyTheme.ink).layoutWeight(1)
        if (this.showCancel) {
          Button(this.cancelling ? 'Stopping…' : 'Cancel', { type: ButtonType.Normal })
            .id('CancelBuild').backgroundColor(HarmonyTheme.softBlue).fontColor(HarmonyTheme.accent)
            .borderRadius(12).height(36).enabled(!this.cancelling)
            .onClick(() => { this.onCancel(); })
        }
      }.width('100%')
      ForEach(this.events.slice(Math.max(0, this.events.length - 3)), (event: ProgressEvent) => {
        Row({ space: 8 }) {
          Text(event.problem ? '!' : '•').fontSize(13).fontWeight(FontWeight.Bold)
            .fontColor(event.problem ? '#B42318' : HarmonyTheme.accent).width(12)
          Text(event.text + (event.count > 1 ? '  ×' + event.count : ''))
            .fontSize(13).lineHeight(18).fontColor(event.problem ? '#B42318' : HarmonyTheme.secondary).layoutWeight(1)
            .maxLines(2).textOverflow({ overflow: TextOverflow.Ellipsis })
        }.width('100%').alignItems(VerticalAlign.Top)
      }, (event: ProgressEvent, index: number) => index + ':' + event.last + ':' + event.count)
      if (this.quietNote.length > 0) {
        Text(this.quietNote).id('QuietNote').fontSize(12).fontColor(HarmonyTheme.secondary)
      }
    }
    .width('100%').alignItems(HorizontalAlign.Start).padding(14)
    .borderRadius(16).backgroundColor(Color.White).border({ width: 1, color: HarmonyTheme.border })
  }
}
