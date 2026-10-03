@Entry
@Component
struct Index {
  @State showNumber: boolean = false;

  build() {
    Column({ space: 24 }) {
      if (this.showNumber) {
        Text('67')
          .id('Number67')
          .fontSize(64)
          .fontWeight(FontWeight.Bold)
      }
      Button('Pokaż 67')
        .id('Show67Button')
        .onClick(() => {
          this.showNumber = true;
        })
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
  }
}
