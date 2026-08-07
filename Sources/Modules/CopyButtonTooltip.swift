import CoreGraphics

/// 工具条图标按钮的悬停提示定位：纯函数计算提示窗口的屏幕坐标。
/// nonactivatingPanel 下系统 toolTip 不可靠，改用独立小窗口显示提示，
/// 此模块仅负责几何计算，便于单测。适用于复制、下载等任意提示按钮。
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

/// 工具条图标按钮悬停状态机：跟踪当前悬停的提示文本（支持多个按钮），
/// 仅在悬停目标变化时返回 true，避免重复刷新提示窗口。
struct ToolbarHoverState {
    private(set) var currentTooltip: String?

    /// 更新当前悬停的提示文本。返回 true 表示目标变化（需刷新提示显示）。
    /// 传入 nil 表示鼠标不在任何提示按钮上。
    @discardableResult
    mutating func update(matchedTooltip: String?) -> Bool {
        guard matchedTooltip != currentTooltip else { return false }
        currentTooltip = matchedTooltip
        return true
    }
}
