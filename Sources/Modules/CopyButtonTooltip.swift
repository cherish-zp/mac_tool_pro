import CoreGraphics

/// 对勾复制按钮的悬停提示定位：纯函数计算提示窗口的屏幕坐标。
/// nonactivatingPanel 下系统 toolTip 不可靠，改用独立小窗口显示提示，
/// 此模块仅负责几何计算，便于单测。
enum CopyButtonTooltip {
    /// 提示与按钮之间的间距。
    static let gap: CGFloat = 6
    /// 提示标签内边距（左右 + 上下）。
    static let padding = CGSize(width: 12, height: 6)

    /// 根据按钮屏幕 frame、文本尺寸、屏幕边界计算提示窗口 frame。
    /// 优先放在按钮正上方；上方放不下则放正下方；横向夹取到屏幕边界。
    static func windowFrame(
        buttonScreenFrame: CGRect,
        labelSize: CGSize,
        screenFrame: CGRect
    ) -> CGRect {
        let width = labelSize.width + padding.width
        let height = labelSize.height + padding.height
        var x = buttonScreenFrame.midX - width / 2
        if x < screenFrame.minX { x = screenFrame.minX }
        if x + width > screenFrame.maxX { x = screenFrame.maxX - width }

        let aboveY = buttonScreenFrame.maxY + gap
        if aboveY + height <= screenFrame.maxY {
            return CGRect(x: x, y: aboveY, width: width, height: height)
        }
        let belowY = buttonScreenFrame.minY - gap - height
        return CGRect(x: x, y: belowY, width: width, height: height)
    }
}

/// 对勾按钮悬停状态机：跟踪鼠标是否悬停在按钮上，仅在状态变化时返回 true。
struct CopyButtonHoverState {
    private(set) var isHovering = false

    /// 更新悬停状态。返回 true 表示状态发生变化（需要刷新提示显示）。
    @discardableResult
    mutating func update(point: CGPoint, buttonFrame: CGRect) -> Bool {
        let now = buttonFrame.contains(point)
        guard now != isHovering else { return false }
        isHovering = now
        return true
    }
}
