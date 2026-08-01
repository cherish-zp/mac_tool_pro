import AppKit

/// 截图模块：AppModule 的第一个实现。
/// F1 触发 -> 启动 ScreenshotCoordinator 进入选区模式。
final class ScreenshotModule: AppModule {
    let id = "screenshot"
    let title = "截图"
    let defaultHotkey = Hotkey.f1

    private var coordinator: ScreenshotCoordinator?

    func perform() {
        DiagLog.write("ScreenshotModule.perform() called")
        let coord = ScreenshotCoordinator()
        self.coordinator = coord
        coord.start()
    }
}
