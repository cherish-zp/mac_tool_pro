import CoreGraphics

/// 自定义颜色面板（NSColorPanel）定位器：纯函数计算面板原点，
/// 将面板放在触发按钮正上方（水平居中），上方放不下回退下方。
/// 确保面板出现在按钮所在屏幕内，避免多屏跑偏或单屏看不到。
enum ColorPanelPositioner {
    /// 面板与按钮之间的间距。
    static let gap: CGFloat = 8

    /// 根据触发按钮的屏幕坐标、屏幕边界、面板尺寸计算面板原点。
    /// 水平：居中对齐按钮，夹取到屏幕边界。
    /// 垂直：优先正上方，放不下回退下方，再不行夹取到屏幕内。
    static func origin(
        buttonScreenFrame: CGRect,
        screenFrame: CGRect,
        panelSize: CGSize
    ) -> CGPoint {
        // 水平：居中对齐按钮
        var x = buttonScreenFrame.midX - panelSize.width / 2
        if x < screenFrame.minX { x = screenFrame.minX }
        if x + panelSize.width > screenFrame.maxX {
            x = screenFrame.maxX - panelSize.width
            if x < screenFrame.minX { x = screenFrame.minX }
        }

        // 垂直：优先正上方
        let aboveY = buttonScreenFrame.maxY + gap
        var y: CGFloat
        if aboveY + panelSize.height <= screenFrame.maxY {
            y = aboveY
        } else {
            y = buttonScreenFrame.minY - gap - panelSize.height
            if y < screenFrame.minY { y = screenFrame.minY }
        }

        return CGPoint(x: x, y: y)
    }
}

extension ColorPanelPositioner {
    /// 计算 NSColorPanel 应使用的窗口层级原始值，确保高于截图覆盖层、
    /// 工具条（overlay+2）和预设色块面板（overlay+3），否则会被全屏覆盖层遮挡。
    static func panelLevelRaw(overlayLevelRaw: Int) -> Int {
        overlayLevelRaw + 4
    }
}
