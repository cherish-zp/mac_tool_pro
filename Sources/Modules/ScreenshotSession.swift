import CoreGraphics
import Foundation

/// 截图会话状态管理器：防止 F1 重复触发导致覆盖层窗口叠加。
/// 纯逻辑，可单测；运行时由 AppDelegate 和 ScreenshotCoordinator 共享同一个实例。
public final class ScreenshotSession {
    public enum State: Equatable {
        case idle
        case active
    }

    public private(set) var state: State = .idle

    /// 会话启动时间，用于超时检测。
    public private(set) var startedAt: Date?

    /// 超时阈值（秒）：超过此时间未完成则判定超时，防止覆盖层未显示时会话卡死。
    public var timeoutInterval: TimeInterval = 15

    public init() {}

    /// 启动新会话。已活跃时返回 false，防止重复触发。
    @discardableResult
    public func start() -> Bool {
        start(at: Date())
    }

    /// 启动新会话并记录启动时间（便于测试注入）。
    @discardableResult
    public func start(at date: Date) -> Bool {
        guard state == .idle else { return false }
        state = .active
        startedAt = date
        return true
    }

    /// 结束会话，重置为空闲状态。
    public func finish() {
        state = .idle
        startedAt = nil
    }

    /// 判断会话是否超时（覆盖层未显示时的安全网）。
    public func isTimedOut(now: Date = Date()) -> Bool {
        guard let startedAt = startedAt, state == .active else { return false }
        return now.timeIntervalSince(startedAt) >= timeoutInterval
    }

    /// ESC 虚拟键码（kVK_Escape = 53）。
    public static let escKeyCode: CGKeyCode = 53
}
