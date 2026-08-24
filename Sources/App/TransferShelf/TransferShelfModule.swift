import AppKit

/// 文件中转模块：菜单栏可开关；拖拽文件时顶部面板自动出现，F2 手动呼出。
final class TransferShelfModule: AppModule {

    let id = "transfer-shelf"
    let title = "文件中转"
    /// F2 = kVK_F2(120)，手动呼出中转面板。
    let defaultHotkey = Hotkey(keyCode: 120)

    private let monitor = MouseDragMonitor()

    /// 手动触发（F2 / 菜单模块项）。
    func perform() {
        TransferShelfPanelController.shared.showPanel(manual: true)
    }

    /// 开启全局拖拽监听。
    func start() {
        monitor.start(
            onDragStart: { TransferShelfPanelController.shared.dragSessionStarted() },
            onDragEnd: { TransferShelfPanelController.shared.dragSessionEnded() }
        )
    }

    /// 停止监听。
    func stop() {
        monitor.stop()
    }
}
