import AppKit

/// 贴图关闭按钮状态机：跟踪悬停状态与闪烁可见性。
/// 非悬停时每 1s 闪烁（可见/不可见切换）；悬停时停止闪烁、保持可见。
/// 纯逻辑，便于单测。
struct PinCloseButtonState: Equatable {
    enum ButtonColor: Equatable {
        case green  // 正常状态：亮绿色
        case red    // 悬停状态：红色
    }

    /// 闪烁间隔（秒）。
    static let blinkInterval: TimeInterval = 1.0

    private(set) var isHovered: Bool = false
    private(set) var blinkVisible: Bool = true

    /// 按钮背景色：悬停时红色，否则亮绿色。
    var color: ButtonColor { isHovered ? .red : .green }

    /// 是否显示X图标：仅悬停时显示。
    var showsX: Bool { isHovered }

    /// 按钮是否可见：悬停时常显，否则由闪烁控制。
    var isVisible: Bool { isHovered || blinkVisible }

    /// 鼠标进入按钮区域：停止闪烁，保持可见。
    mutating func onHoverEnter() { isHovered = true }

    /// 鼠标离开按钮区域：恢复闪烁，重置为可见。
    mutating func onHoverExit() { isHovered = false; blinkVisible = true }

    /// 闪烁周期回调（每 blinkInterval 秒调用），切换可见性。悬停时不闪烁。
    mutating func onBlinkTick() {
        guard !isHovered else { return }
        blinkVisible.toggle()
    }
}
