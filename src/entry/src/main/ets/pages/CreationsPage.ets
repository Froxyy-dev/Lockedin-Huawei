import { router } from '@kit.ArkUI';
import { common } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { HarnessClient, Project, describeError } from '../model/HarnessClient';
import { HarmonyTheme } from '../theme/DesignTokens';

interface CreationPageParams {
  projectId: string;
}

@Component
struct ProjectRow {
  project: Project = { id: '', name: '', created: '', current_revision: 0, latest_state: '' };
  onOpen: () => void = () => {};

  build() {
    Column({ space: 4 }) {
      Text(this.project.name).fontSize(17).fontWeight(FontWeight.Medium).fontColor(HarmonyTheme.ink)
      Row({ space: 8 }) {
        Text('Revision ' + this.project.current_revision).fontSize(13).fontColor(HarmonyTheme.secondary)
        Text('·').fontSize(13).fontColor(HarmonyTheme.secondary)
        Text(this.project.latest_state || 'drafted').fontSize(13).fontColor(HarmonyTheme.accent)
      }
    }
    .alignItems(HorizontalAlign.Start)
    .width('100%')
    .padding(16)
    .borderRadius(18)
    .backgroundColor(Color.White)
    .border({ width: 1, color: HarmonyTheme.border })
    .onClick(this.onOpen)
  }
}

@Entry
@Component
struct CreationsPage {
  @State projects: Project[] = [];
  @State loading: boolean = true;
  @State error: string = '';
  @State newName: string = '';
  @State creating: boolean = false;
  private client?: HarnessClient;

  aboutToAppear(): void {
    this.load();
  }

  private async load(): Promise<void> {
    this.loading = true;
    this.error = '';
    try {
      const context = this.getUIContext().getHostContext() as common.UIAbilityContext;
      const config = HarnessClient.loadConfig(context);
      this.client = new HarnessClient(config);
      this.projects = await this.client.projects();
    } catch (err) {
      this.error = 'Could not load creations: ' + describeError(err);
      hilog.error(0x0001, 'Harness', 'load projects failed: %{public}s', this.error);
    } finally {
      this.loading = false;
    }
  }

  private openProject(id: string): void {
    const params: CreationPageParams = { projectId: id };
    router.pushUrl({ url: 'pages/CreationPage', params: params });
  }

  private async createProject(): Promise<void> {
    const name = this.newName.trim();
    if (!name || !this.client) { return; }
    this.creating = true;
    this.error = '';
    try {
      const project = await this.client.createProject(name);
      this.newName = '';
      this.openProject(project.id);
    } catch (err) {
      this.error = 'Could not create: ' + describeError(err);
    } finally {
      this.creating = false;
    }
  }

  build() {
    Column({ space: 14 }) {
      Row() {
        Button('‹', { type: ButtonType.Normal })
          .id('CreationsBack').backgroundColor(Color.Transparent).fontColor(HarmonyTheme.secondary)
          .fontSize(20).width(36).height(36).padding(0)
          .onClick(() => { router.back(); })
        Text('Creations').fontSize(26).fontWeight(FontWeight.Bold).fontColor(HarmonyTheme.ink).margin({ left: 6 })
      }.width('100%').alignItems(VerticalAlign.Center)

      Row({ space: 10 }) {
        TextInput({ text: this.newName, placeholder: 'Name your new creation' })
          .id('NewCreationName')
          .layoutWeight(1)
          .fontSize(15)
          .backgroundColor('#EDF2F8')
          .borderRadius(12)
          .onChange((value: string) => { this.newName = value; })
        Button(this.creating ? '…' : 'New', { type: ButtonType.Normal })
          .id('NewCreationButton')
          .backgroundColor(HarmonyTheme.accent).fontColor(Color.White)
          .borderRadius(12).height(40).padding({ left: 16, right: 16 })
          .enabled(this.newName.trim().length > 0 && !this.creating)
          .onClick(() => { this.createProject(); })
      }.width('100%')

      if (this.error.length > 0) {
        Text(this.error).fontSize(13).fontColor('#B42318').width('100%')
      }

      if (this.loading) {
        LoadingProgress().width(36).height(36).color(HarmonyTheme.accent)
      } else if (this.projects.length === 0) {
        Text('No creations yet. Start one above.')
          .fontSize(14).fontColor(HarmonyTheme.secondary).margin({ top: 20 })
      } else {
        List({ space: 10 }) {
          ForEach(this.projects, (project: Project) => {
            ListItem() {
              ProjectRow({ project: project, onOpen: () => { this.openProject(project.id); } })
            }
          }, (project: Project) => project.id)
        }.width('100%').layoutWeight(1)
      }
    }
    .width('100%').height('100%')
    .padding({ left: 24, right: 24, top: 18, bottom: 20 })
    .alignItems(HorizontalAlign.Start)
    .backgroundColor(HarmonyTheme.background)
  }
}
