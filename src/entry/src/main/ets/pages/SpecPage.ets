import { router } from '@kit.ArkUI';
import { common } from '@kit.AbilityKit';
import { HarnessClient } from '../model/HarnessClient';
import { HarmonyTheme } from '../theme/DesignTokens';

export interface SpecPageParams {
  projectId: string;
  n: number;
}

interface SpecLine {
  kind: string;
  level: number;
  content: string;
}

function countLeadingHashes(s: string): number {
  let i = 0;
  while (i < s.length && s.charAt(i) === '#') {
    i++;
  }
  return i;
}

function parseSpecLines(spec: string): SpecLine[] {
  const rawLines = spec.split('\n');
  const lines: SpecLine[] = [];
  for (let i = 0; i < rawLines.length; i++) {
    const trimmed = rawLines[i].trim();
    if (trimmed.length === 0) {
      lines.push({ kind: 'blank', level: 0, content: '' });
      continue;
    }
    const hashes = countLeadingHashes(trimmed);
    if (hashes > 0 && hashes <= 6 && trimmed.charAt(hashes) === ' ') {
      lines.push({ kind: 'heading', level: hashes, content: trimmed.substring(hashes + 1).trim() });
      continue;
    }
    if (trimmed.startsWith('- ') || trimmed.startsWith('* ')) {
      lines.push({ kind: 'bullet', level: 0, content: trimmed.substring(2).trim() });
      continue;
    }
    lines.push({ kind: 'text', level: 0, content: trimmed });
  }
  return lines;
}

@Component
struct SpecLineView {
  line: SpecLine = { kind: 'text', level: 0, content: '' };

  build() {
    if (this.line.kind === 'heading') {
      Text(this.line.content)
        .fontSize(this.line.level <= 1 ? 22 : this.line.level === 2 ? 18 : 16)
        .fontWeight(FontWeight.Bold)
        .fontColor(HarmonyTheme.ink)
        .width('100%')
        .margin({ top: 14, bottom: 4 })
    } else if (this.line.kind === 'bullet') {
      Row({ space: 8 }) {
        Text('•').fontSize(14).fontColor(HarmonyTheme.accent)
        Text(this.line.content).fontSize(14).lineHeight(20).fontColor(HarmonyTheme.ink).layoutWeight(1)
      }.width('100%').alignItems(VerticalAlign.Top).margin({ left: 6 })
    } else if (this.line.kind === 'blank') {
      Row().height(8).width('100%')
    } else {
      Text(this.line.content).fontSize(14).lineHeight(20).fontColor(HarmonyTheme.ink).width('100%')
    }
  }
}

@Entry
@Component
struct SpecPage {
  @State lines: SpecLine[] = [];
  @State loading: boolean = true;
  @State error: string = '';
  private projectId: string = '';
  private n: number = 0;

  aboutToAppear(): void {
    const params = router.getParams() as SpecPageParams;
    this.projectId = params?.projectId ?? '';
    this.n = params?.n ?? 0;
    this.load();
  }

  private async load(): Promise<void> {
    this.loading = true;
    this.error = '';
    try {
      const context = this.getUIContext().getHostContext() as common.UIAbilityContext;
      const config = HarnessClient.loadConfig(context);
      const client = new HarnessClient(config);
      const spec = await client.spec(this.projectId, this.n);
      this.lines = parseSpecLines(spec);
    } catch (err) {
      this.error = 'Could not load spec: ' + String(err);
    } finally {
      this.loading = false;
    }
  }

  build() {
    Column({ space: 0 }) {
      Row() {
        Button('‹', { type: ButtonType.Normal })
          .id('SpecBack').backgroundColor(Color.Transparent).fontColor(HarmonyTheme.secondary)
          .fontSize(20).width(36).height(36).padding(0)
          .onClick(() => { router.back(); })
        Text('Full spec · #' + this.n).fontSize(20).fontWeight(FontWeight.Bold)
          .fontColor(HarmonyTheme.ink).margin({ left: 6 })
      }.width('100%').alignItems(VerticalAlign.Center).margin({ bottom: 12 })

      if (this.error.length > 0) {
        Text(this.error).fontSize(13).fontColor('#B42318').width('100%')
      }

      if (this.loading) {
        LoadingProgress().width(36).height(36).color(HarmonyTheme.accent)
      } else {
        Scroll() {
          Column({ space: 2 }) {
            ForEach(this.lines, (line: SpecLine) => {
              SpecLineView({ line: line })
            }, (line: SpecLine, index: number) => String(index))
          }.width('100%').alignItems(HorizontalAlign.Start)
        }.layoutWeight(1).width('100%')
      }
    }
    .width('100%').height('100%')
    .padding({ left: 24, right: 24, top: 18, bottom: 20 })
    .alignItems(HorizontalAlign.Start)
    .backgroundColor(HarmonyTheme.background)
  }
}
