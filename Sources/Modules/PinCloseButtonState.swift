import AppKit

/// 贴图关闭按钮状态机：支持两种指示样式模式。
/// - cornerDot（左上角圆点）：非悬停时每 1s 闪烁（可见/不可见切换）；悬停时停止闪烁、保持可见。
/// - topBar（顶部横条）：按钮平时隐藏；鼠标悬停贴图时浮现红色 X，移开隐藏，不闪烁。
/// 纯逻辑，便于单测。
struct PinCloseButtonState: Equatable {
    enum ButtonColor: Equatable {
        case green  // 正常状态：亮绿色
        case red    // 悬停状态：红色
    }

    enum Mode: Equatable {
        case cornerDot  // 左上角圆点闪烁
        case topBar     // 顶部横条呼吸灯（按钮仅悬停贴图时浮现）

        /// 由呼吸灯样式映射按钮模式。
        init(_ style: PinIndicatorStyle) {
            self = style == .topBar ? .topBar : .cornerDot
        }
    }

    /// 闪烁间隔（秒）。
    static let blinkInterval: TimeInterval = 1.0

    private(set) var mode: Mode
    private(set) var isHovered: Bool = false
    private(set) var blinkVisible: Bool = true
    private(set) var isRevealed: Bool = false

    init(mode: Mode = .cornerDot) {
        self.mode = mode
    }

    /// 切换样式模式，重置为该模式的干净初始状态。
    mutating func setMode(_ newMode: Mode) {
        mode = newMode
        isHovered = false
        blinkVisible = true
        isRevealed = false
    }

    /// 按钮背景色：横条模式浮现即红色；圆点模式悬停时红色，否则亮绿色。
    var color: ButtonColor {
        switch mode {
        case .topBar: return .red
        case .cornerDot: return isHovered ? .red : .green
        }
    }

    /// 是否显示X图标：横条模式浮现即显示；圆点模式仅悬停时显示。
    var showsX: Bool {
        switch mode {
        case .topBar: return true
        case .cornerDot: return isHovered
        }
    }

    /// 按钮是否可见。
    var isVisible: Bool {
        switch mode {
        case .topBar: return isRevealed
        case .cornerDot: return isHovered || blinkVisible
        }
    }

    /// 鼠标进入按钮区域（圆点模式）：停止闪烁，保持可见。
    mutating func onHoverEnter() { isHovered = true }

    /// 鼠标离开按钮区域（圆点模式）：恢复闪烁，重置为可见。
    mutating func onHoverExit() { isHovered = false; blinkVisible = true }

    /// 鼠标进入贴图区域（横条模式）：浮现关闭按钮。
    mutating func onImageHoverEnter() { isRevealed = true }

    /// 鼠标离开贴图区域（横条模式）：隐藏关闭按钮。
    mutating func onImageHoverExit() { isRevealed = false }

    /// 闪烁周期回调（每 blinkInterval 秒调用），切换可见性。悬停时不闪烁；横条模式不闪烁。
    mutating func onBlinkTick() {
        guard mode == .cornerDot, !isHovered else { return }
        blinkVisible.toggle()
    }
}
