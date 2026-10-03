import { abilityAccessCtrl, common } from '@kit.AbilityKit';
import { util } from '@kit.ArkTS';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { NativeAudio } from '../care/NativeAudio';
import { ShakeTrigger } from '../care/ShakeTrigger';
import { VoiceConversation, CareConfig } from '../care/VoiceConversation';

interface ConversationTurn {
  id: number;
  speaker: string;
  text: string;
  grandma: boolean;
}

@Entry
@Component
struct Index {
  @State private title: string = 'Care Guardian';
  @State private message: string = 'Shake three times. I am here for you.';
  @State private conversation: ConversationTurn[] = [];
  private nextTurnId: number = 0;
  private conversationScroller: Scroller = new Scroller();
  @State private busy: boolean = false;
  @State private showAudioOptions: boolean = false;
  @State private laptopAudio: boolean = true;
  private shake: ShakeTrigger = new ShakeTrigger();
  private voice: VoiceConversation = new VoiceConversation();
  private diagnostic: NativeAudio = new NativeAudio();
  private config?: CareConfig;
  private alive: boolean = false;
  @StorageLink('guardianForeground') @Watch('foregroundChanged') private visible: boolean = true;
  private pendingShake: boolean = false;

  aboutToAppear(): void {
    this.alive = true;
    const context = this.getUIContext().getHostContext() as common.UIAbilityContext;
    context.resourceManager.getRawFileContent('care.json').then((data: Uint8Array): void => {
      this.config = JSON.parse(util.TextDecoder.create('utf-8').decodeWithStream(data)) as CareConfig;
      this.title = this.config.name; this.laptopAudio = this.config.audioSource !== 'native';
      try { this.shake.start((): void => {
        if (this.visible) { this.begin(); }
        else {
          this.pendingShake = true;
          hilog.info(0x0001, 'GuardianWake', 'BACKGROUND_SHAKE_REQUEST');
        }
      }); }
      catch (error) { this.message = 'Shake unavailable on this device.'; }
    }).catch((error: Error): void => { this.message = 'Configuration error: ' + error.message; });
  }

  aboutToDisappear(): void {
    this.alive = false; this.shake.stop(); this.voice.stop(); this.diagnostic.stop();
  }

  private foregroundChanged(): void {
    if (this.visible && this.pendingShake && this.config) { this.pendingShake = false; this.begin(); }
  }

  onPageHide(): void { this.voice.stop(); this.diagnostic.stop(); this.busy = false; this.shake.arm(); }

  private async permission(): Promise<boolean> {
    const context = this.getUIContext().getHostContext() as common.UIAbilityContext;
    const result = await abilityAccessCtrl.createAtManager().requestPermissionsFromUser(context, ['ohos.permission.MICROPHONE']);
    return result.authResults[0] === 0;
  }

  private async begin(): Promise<void> {
    if (this.busy || !this.config) { return; }
    this.busy = true; this.conversation = [];
    try {
      if (!this.laptopAudio && !(await this.permission())) { throw new Error('Microphone permission denied'); }
      await this.voice.start(this.config, this.getUIContext().getHostContext() as common.UIAbilityContext, this.laptopAudio,
        (message: string): void => { if (this.alive) { this.message = message; } },
        (text: string): void => { if (this.alive) { this.appendTurn(text); } },
        (): void => { if (this.alive) { this.busy = false; this.shake.arm(); } });
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

  private appendTurn(text: string): void {
    const grandma = text.startsWith('You: ');
    const prefix = grandma ? 'You: ' : 'Care Guardian: ';
    const turn: ConversationTurn = {
      id: this.nextTurnId++, speaker: grandma ? 'Grandma' : 'Care Guardian',
      text: text.startsWith(prefix) ? text.substring(prefix.length) : text, grandma: grandma
    };
    this.conversation = [...this.conversation, turn];
    setTimeout((): void => {
      if (this.alive) { this.conversationScroller.scrollEdge(Edge.Bottom); }
    }, 80);
  }

  private statusText(): string {
    if (this.message === 'Care Guardian is speaking') { return 'Speaking'; }
    if (this.message === 'Shake three times. I am here for you.') { return 'Ready'; }
    return this.message;
  }

  build() {
    Column({ space: 20 }) {
      Row({ space: 12 }) {
        Image($r('app.media.guardian')).width(46).height(46).borderRadius(14)
        Column({ space: 3 }) {
          Text(this.title).fontSize(25).fontWeight(FontWeight.Bold).fontColor('#18263C')
          Text('Here with you.').fontSize(14).fontColor('#526784')
        }.alignItems(HorizontalAlign.Start)
        Blank()
      }.width('100%').gesture(
        LongPressGesture({ repeat: false }).onAction((): void => { this.showAudioOptions = !this.showAudioOptions; })
      )

      Row({ space: 8 }) {
        Circle().width(7).height(7).fill(this.busy ? '#246BFD' : '#7C90AA')
        Text(this.statusText()).fontSize(14).fontColor('#526784').layoutWeight(1)
      }.width('100%').padding({ left: 4, right: 4 })

      if (this.busy || this.conversation.length > 0) {
        Column({ space: 14 }) {
          Text('CONVERSATION').fontSize(11).fontWeight(FontWeight.Bold)
            .fontColor('#526784').letterSpacing(1.4).width('100%')
          Scroll(this.conversationScroller) {
            Column({ space: 14 }) {
              ForEach(this.conversation, (turn: ConversationTurn) => {
                Row() {
                  if (turn.grandma) { Blank().width(24) }
                  Column({ space: 7 }) {
                    Text(turn.speaker).fontSize(12).fontWeight(FontWeight.Medium)
                      .fontColor(turn.grandma ? '#315FB3' : '#526784').width('100%')
                    Text(turn.text).fontSize(20).fontColor('#18263C').width('100%')
                  }.layoutWeight(1).padding(16).borderRadius(22)
                    .backgroundColor(turn.grandma ? '#E8EFFD' : '#FFFFFF')
                  if (!turn.grandma) { Blank().width(24) }
                }.width('100%')
              }, (turn: ConversationTurn): string => turn.id.toString())
              if (this.conversation.length === 0) {
                Text('Your conversation will appear here.').fontSize(17).fontColor('#526784')
                  .width('100%').padding({ top: 20 })
              }
            }.width('100%').padding({ bottom: 20 })
          }.layoutWeight(1).width('100%').align(Alignment.Top).scrollBar(BarState.Off)
        }.layoutWeight(1).width('100%')
      } else {
        Column({ space: 14 }) {
          Image($r('app.media.guardian')).width(76).height(76).borderRadius(23)
          Text('I am here for you.').fontSize(28).fontWeight(FontWeight.Medium).fontColor('#18263C')
          Text('Shake three times when you need me.').fontSize(17).fontColor('#526784')
            .textAlign(TextAlign.Center)
        }.layoutWeight(1).width('100%').justifyContent(FlexAlign.Center)
      }

      if (this.showAudioOptions) {
        Column({ space: 12 }) {
          Text('AUDIO OPTIONS').fontSize(11).fontWeight(FontWeight.Bold).fontColor('#526784').width('100%')
          if (this.busy) {
            Button('Stop session').onClick((): void => {
              this.voice.stop(); this.diagnostic.stop(); this.busy = false; this.shake.arm();
              this.message = 'Check-in complete';
            })
          }
          Button('Test native audio').fontSize(15).enabled(!this.busy)
            .onClick((): void => { this.audioCheck(); })
          Row({ space: 12 }) {
            Text('Laptop audio').fontSize(16).fontColor('#18263C').layoutWeight(1)
            Toggle({ type: ToggleType.Switch, isOn: this.laptopAudio }).enabled(!this.busy)
              .onChange((value: boolean): void => { this.laptopAudio = value; })
          }.width('100%')
        }.width('100%').padding(18).backgroundColor('#FFFFFF').borderRadius(20)
      }
    }.width('100%').height('100%').padding({ top: 24, bottom: 24, left: 24, right: 24 })
      .backgroundColor('#F5F7FB')
  }
}
