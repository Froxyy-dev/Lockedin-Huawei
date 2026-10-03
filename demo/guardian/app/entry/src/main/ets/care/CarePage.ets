import { abilityAccessCtrl, common } from '@kit.AbilityKit';
import { util } from '@kit.ArkTS';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { NativeAudio } from './NativeAudio';
import { ShakeTrigger } from './ShakeTrigger';
import { VoiceConversation, CareConfig } from './VoiceConversation';

@Entry
@Component
struct Index {
  @State private title: string = 'Care Guardian';
  @State private message: string = 'Shake three times. I am here for you.';
  @State private transcript: string = '';
  @State private busy: boolean = false;
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
      catch (error) { this.message = 'Shake unavailable. Use Start check-in.'; }
    }).catch((error: Error): void => { this.message = 'Configuration error: ' + error.message; });
  }

  aboutToDisappear(): void {
    this.alive = false; this.shake.stop(); this.voice.stop(); this.diagnostic.stop();
  }

  onPageHide(): void {
    this.voice.stop(); this.diagnostic.stop(); this.busy = false;
    this.shake.arm(); this.message = 'Shake three times. I am here for you.';
  }

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
    Column({ space: 22 }) {
      Row() {
        Text('THE MISSING APP').fontSize(12).fontWeight(FontWeight.Medium).fontColor('#416393').letterSpacing(2)
        Blank()
        Text('DEMO').fontSize(12).fontColor('#416393')
      }.width('100%')
      Blank().height(28)
      Text(this.title).fontSize(38).fontWeight(FontWeight.Bold).fontColor('#18263C').width('100%')
      Text('A little reassurance. Help when it matters.').fontSize(17).fontColor('#526784').width('100%')
      Column({ space: 18 }) {
        Text(this.busy ? '✦' : '♡').fontSize(64).fontColor('#246BFD')
        Text(this.message).fontSize(23).fontWeight(FontWeight.Medium).textAlign(TextAlign.Center).fontColor('#18263C')
      }.width('100%').height(235).padding(24).backgroundColor('#FFFFFF').borderRadius(28)
      Text(this.transcript).fontSize(18).fontColor('#243B5C').width('100%').maxLines(4)
      Blank()
      Button(this.busy ? 'End / Reset' : 'Start check-in').width('100%').height(58).fontSize(19)
        .backgroundColor('#246BFD').onClick((): void => {
          if (this.busy) { this.voice.stop(); this.diagnostic.stop(); this.busy = false; this.shake.arm(); this.message = 'Shake three times. I am here for you.'; }
          else { this.begin(); }
        })
      Row({ space: 14 }) {
        Button('Test native audio').fontSize(14).enabled(!this.busy).onClick((): void => { this.audioCheck(); })
        Toggle({ type: ToggleType.Switch, isOn: this.laptopAudio }).enabled(!this.busy)
          .onChange((value: boolean): void => { this.laptopAudio = value; })
        Text('Laptop audio').fontSize(13).fontColor('#526784')
      }
      Text('Demo companion · not an emergency service').fontSize(12).fontColor('#526784')
    }.width('100%').height('100%').padding({ top: 26, bottom: 28, left: 24, right: 24 }).backgroundColor('#F5F7FB')
  }
}
