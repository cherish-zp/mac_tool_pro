import CoreGraphics

/// 截图会话状态管理器：防止 F1 重复触发导致覆盖层窗口叠加。
/// 纯逻辑，可单测；运行时由 AppDelegate 和 ScreenshotCoordinator 共享同一个实例。
public final class ScreenshotSession {
    public enum State: Equatable {
        case idle
        case active
    }

    public private(set) var state: State = .idle

    public init() {}

    /// 启动新会话。已活跃时返回 false，防止重复触发。
    @discardableResult
    public func start() -> Bool {
        guard state == .idle else { return false }
        state = .active
        return true
    }

    /// 结束会话，重置为空闲状态。
    public func finish() {
        state = .idle
    }

    /// ESC 虚拟键码（kVK_Escape = 53）。
    public static let escKeyCode: CGKeyCode = 53
}
