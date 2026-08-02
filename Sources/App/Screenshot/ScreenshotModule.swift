import AppKit

/// 截图模块：AppModule 的第一个实现。
/// F1 触发 -> 启动 ScreenshotCoordinator 进入选区模式。
/// 使用 ScreenshotSession 防止重复触发导致覆盖层叠加。
final class ScreenshotModule: AppModule {
    let id = "screenshot"
    let title = "截图"
    let defaultHotkey = Hotkey.f1

    let session = ScreenshotSession()
    private var coordinator: ScreenshotCoordinator?

    func perform() {
        // 防止重复触发：会话活跃时直接忽略
        guard session.start() else {
            DiagLog.write("ScreenshotModule.perform() ignored - session already active")
            return
        }
        DiagLog.write("ScreenshotModule.perform() called")

        // 先结束旧的协调器（清理残留窗口）
        coordinator?.finish()

        let coord = ScreenshotCoordinator()
        coord.onFinished = { [weak self] in
            self?.session.finish()
        }
        self.coordinator = coord
        coord.start()
    }
}
