import { hilog } from '@kit.PerformanceAnalysisKit';
import { HarmonyTheme } from '../theme/DesignTokens';

@Component
export struct PromptCard {
  @Link prompt: string;
  controller: TextAreaController = new TextAreaController();
  @State voicePreview: boolean = false;
  private voiceTimer: number = -1;

  aboutToDisappear(): void {
    clearTimeout(this.voiceTimer);
  }

  build() {
    Column({ space: 4 }) {
      TextArea({ text: this.prompt, placeholder: 'Describe what you need…', controller: this.controller })
        .id('NeedPrompt')
        .fontSize(18)
        .fontColor(HarmonyTheme.ink)
        .backgroundColor(Color.Transparent)
        .borderRadius(0)
        .padding({ left: 2, right: 2, top: 4, bottom: 4 })
        .height(104)
        .maxLength(500)
        .enterKeyType(EnterKeyType.Done)
        .onSubmit(() => { this.controller.stopEditing(); })
        .onChange((value: string) => { this.prompt = value; })
      Row() {
        Text('✦').fontSize(22).fontColor(HarmonyTheme.accent).accessibilityLevel('no')
        Blank()
        Button({ type: ButtonType.Circle }) {
          Image($r('app.media.cap_voice')).width(20).height(20)
        }
        .id('VoicePreview')
        .width(40).height(40)
        .backgroundColor(this.voicePreview ? '#D5E4FF' : '#EDF2F8')
        .border({ width: 1, color: this.voicePreview ? HarmonyTheme.accent : Color.Transparent })
        .accessibilityText('Voice input preview')
        .onClick(() => {
          this.voicePreview = !this.voicePreview;
          hilog.info(0x0001, 'HarmonyCreate', 'Microphone preview tapped; no recording or STT');
          clearTimeout(this.voiceTimer);
          this.voiceTimer = setTimeout(() => { this.voicePreview = false; }, 1600);
        })
      }.width('100%')
    }
    .padding(16)
    .width('100%')
    .borderRadius(24)
    .backgroundColor('#FFFFFF')
    .border({ width: 1, color: HarmonyTheme.border })
    .shadow({ radius: 18, color: '#081D4270', offsetY: 6 })
  }
}
