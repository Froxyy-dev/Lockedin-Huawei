import { abilityAccessCtrl, common } from '@kit.AbilityKit';
import { util } from '@kit.ArkTS';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { NativeAudio } from '../care/NativeAudio';
import { ShakeTrigger } from '../care/ShakeTrigger';
import { VoiceConversation, CareConfig } from '../care/VoiceConversation';

@Entry
@Component
struct Index {
  @State private title: string = 'Care Guardian';
  @State private message: string = 'Shake three times. I am here for you.';
  @State private transcript: string = '';
  @State private busy: boolean = false;
  @State private showAudioOptions: boolean = false;
  @State private laptopAudio: boolean = true;
  private shake: ShakeTrigger = new ShakeTrigger();
  private voice: VoiceConversation = new VoiceConversation();
  private diagnostic: NativeAudio = new NativeAudio();
  private config?: CareConfig;
  private alive: boolean = false;

  aboutToAppear(): void {
    this.alive = true;
    const context = this.getUIContext().getHostContext() as common.UIAbilityContext;
    context.resourceManager.getRawFileContent('care.json').then((data: Uint8Array): void => {
      this.config = JSON.parse(util.TextDecoder.create('utf-8').decodeWithStream(data)) as CareConfig;
      this.title = this.config.name; this.laptopAudio = this.config.audioSource !== 'native';
      try { this.shake.start((): void => { this.begin(); }); }
      catch (error) { this.message = 'Shake unavailable on this device.'; }
    }).catch((error: Error): void => { this.message = 'Configuration error: ' + error.message; });
  }

  aboutToDisappear(): void {
    this.alive = false; this.shake.stop(); this.voice.stop(); this.diagnostic.stop();
  }

  onPageHide(): void { this.voice.stop(); this.diagnostic.stop(); this.busy = false; this.shake.arm(); }

  private async permission(): Promise<boolean> {
    const context = this.getUIContext().getHostContext() as common.UIAbilityContext;
    const result = await abilityAccessCtrl.createAtManager().requestPermissionsFromUser(context, ['ohos.permission.MICROPHONE']);
    return result.authResults[0] === 0;
  }

  private async begin(): Promise<void> {
    if (this.busy || !this.config) { return; }
    this.busy = true; this.transcript = '';
    try {
      if (!this.laptopAudio && !(await this.permission())) { throw new Error('Microphone permission denied'); }
      await this.voice.start(this.config, this.getUIContext().getHostContext() as common.UIAbilityContext, this.laptopAudio,
        (message: string): void => { if (this.alive) { this.message = message; } },
        (text: string): void => { if (this.alive) { this.transcript = text; } });
    } catch (error) {
      this.message = 'Error: ' + (error as Error).message;
      hilog.error(0x0001, 'CareGuardian', 'START error %{public}s', JSON.stringify(error));
      await this.voice.stop(); this.busy = false; this.shake.arm();
    }
  }

  private async audioCheck(): Promise<void> {
    if (this.busy) { return; } this.busy = true;
    try {
      if (!(await this.permission())) { throw new Error('Microphone permission denied'); }
      const context = this.getUIContext().getHostContext() as common.UIAbilityContext;
      await this.diagnostic.echo(context.cacheDir, (text: string): void => { this.message = text; });
    } catch (error) { this.message = 'Audio error: ' + (error as Error).message; await this.diagnostic.stop(); }
    finally { this.busy = false; this.shake.arm(); }
  }

  build() {
    Scroll() {
      Column({ space: 18 }) {
        Row({ space: 10 }) {
          Image($r('app.media.guardian')).width(40).height(40).borderRadius(12)
          Text('CARE GUARDIAN').fontSize(12).fontWeight(FontWeight.Bold)
            .fontColor('#416393').letterSpacing(1.5)
        }.width('100%').gesture(
          LongPressGesture({ repeat: false }).onAction((): void => { this.showAudioOptions = !this.showAudioOptions; })
        )

        Column({ space: 8 }) {
          Text(this.title).fontSize(36).fontWeight(FontWeight.Bold).fontColor('#18263C').width('100%')
          Text('A little reassurance. Help when it matters.')
            .fontSize(16).fontColor('#526784').width('100%')
        }.width('100%')

        Column({ space: 16 }) {
          Row() {
            Text(this.busy ? '✦' : '♡').fontSize(42).fontColor('#246BFD')
            Blank()
            Text(this.busy ? 'IN PROGRESS' : 'READY TO CHECK IN')
              .fontSize(11).fontWeight(FontWeight.Bold).fontColor('#416393').letterSpacing(1)
          }.width('100%')
          Text(this.message).fontSize(22).fontWeight(FontWeight.Medium)
            .fontColor('#18263C').width('100%')
          Text(this.busy ? 'Your check-in is underway.' : 'Shake three times to start a check-in.')
            .fontSize(14).fontColor('#526784').width('100%')
        }.width('100%').padding(24).backgroundColor('#FFFFFF').borderRadius(24)

        if (this.transcript.length > 0) {
          Column({ space: 8 }) {
            Text('CONVERSATION').fontSize(11).fontWeight(FontWeight.Bold)
              .fontColor('#416393').letterSpacing(1)
            Text(this.transcript).fontSize(17).fontColor('#243B5C').maxLines(5)
              .width('100%')
          }.width('100%').padding(20).backgroundColor('#FFFFFF').borderRadius(20)
        }

        if (this.busy) {
          Button('End / Reset')
            .width('100%').height(58).fontSize(19).backgroundColor('#246BFD')
            .onClick((): void => {
              this.voice.stop(); this.diagnostic.stop(); this.busy = false; this.shake.arm();
              this.message = 'Shake three times. I am here for you.';
            })
        }

        if (this.showAudioOptions) {
          Column({ space: 16 }) {
            Text('AUDIO OPTIONS').fontSize(11).fontWeight(FontWeight.Bold)
              .fontColor('#416393').letterSpacing(1).width('100%')
            Button('Test native audio').fontSize(15).enabled(!this.busy)
              .onClick((): void => { this.audioCheck(); })
            Row({ space: 12 }) {
              Column({ space: 4 }) {
                Text('Laptop audio fallback').fontSize(16).fontWeight(FontWeight.Medium)
                  .fontColor('#18263C')
                Text('Use only when native audio is unavailable.')
                  .fontSize(13).fontColor('#526784')
              }.layoutWeight(1)
              Toggle({ type: ToggleType.Switch, isOn: this.laptopAudio }).enabled(!this.busy)
                .onChange((value: boolean): void => { this.laptopAudio = value; })
            }.width('100%')
          }.width('100%').padding(20).backgroundColor('#FFFFFF').borderRadius(20)
        }
      }.width('100%').padding({ top: 26, bottom: 28, left: 24, right: 24 })
    }.width('100%').height('100%').backgroundColor('#F5F7FB')
  }
}
