import CoreGraphics

/// 滚动截图会话状态机：管理滚动截取的帧序列与模式。
///
/// 状态流转：ready（工具栏已显示，等待开始）→ capturing（截帧中）→ done（已停止，待拼接）。
/// 模式：auto（自动滚动，点"开始"触发）、manual（手动滚动，鼠标滚动触发）。
/// 纯逻辑，便于单测。
public struct ScrollCaptureSession {
    public enum State: Equatable {
        case ready
        case capturing
        case done
    }

    public enum Mode: Equatable {
        case auto
        case manual
    }

    public private(set) var frames: [CGImage] = []
    public private(set) var state: State = .ready
    public private(set) var mode: Mode?
    public let maxFrames: Int

    /// 自动滚动 delta：负值 = 向下滚动（内容上移、新内容出现在底部），
    /// 用于长截图自动滚动模式。
    public static let autoScrollDelta: Int32 = -30

    public init(maxFrames: Int = 30) {
        self.maxFrames = maxFrames
    }

    public var count: Int { frames.count }
    public var isFull: Bool { frames.count >= maxFrames }
    public var isDone: Bool { state == .done }

    /// 开始自动滚动截取。仅在 ready 状态有效。
    public mutating func startAuto() {
        guard state == .ready else { return }
        mode = .auto
        state = .capturing
    }

    /// 开始手动滚动截取（鼠标滚动触发）。仅在 ready 状态有效。
    public mutating func startManual() {
        guard state == .ready else { return }
        mode = .manual
        state = .capturing
    }

    /// 尝试添加一帧。仅在 capturing 状态有效；首帧总是添加，后续帧仅在内容变化时添加。
    /// 到达最大帧数时自动转为 done。返回是否实际添加。
    @discardableResult
    public mutating func tryAdd(_ frame: CGImage) -> Bool {
        guard state == .capturing else { return false }
        if frames.isEmpty {
            frames.append(frame)
            if isFull { state = .done }
            return true
        }
        guard !isFull else { state = .done; return false }
        if ScrollStitcher.contentChanged(top: frames.last!, bottom: frame) {
            frames.append(frame)
            if isFull { state = .done }
            return true
        }
        return false
    }

    /// 停止截取，转为 done 状态。
    public mutating func stop() {
        state = .done
    }
}

extension ScrollCaptureSession {
    /// 将选区从视图坐标（左下原点）转为显示器坐标（左上原点），
    /// 用于 CGDisplayCreateImage 的 rect 参数。
    public static func displayCaptureRect(viewRect: CGRect, screenHeight: CGFloat) -> CGRect {
        CGRect(x: viewRect.origin.x,
               y: screenHeight - viewRect.maxY,
               width: viewRect.width,
               height: viewRect.height)
    }

    /// 将显示器坐标（相对于显示器左上角）转为全局屏幕坐标（左上原点），
    /// 用于 CGWindowListCreateImage 的 rect 参数（支持多屏偏移）。
    public static func globalCaptureRect(displayRect: CGRect, displayBounds: CGRect) -> CGRect {
        CGRect(x: displayBounds.origin.x + displayRect.origin.x,
               y: displayBounds.origin.y + displayRect.origin.y,
               width: displayRect.width,
               height: displayRect.height)
    }
}
