import Foundation
import CoreGraphics

/// 全局拖拽判定状态机：mouseDown 后移动超过阈值视为拖拽会话进行。
/// macOS 无全局拖拽通知，此策略配合 CGEventTap 的鼠标事件使用。
public struct TransferShelfDragPolicy {
    public static let dragThreshold: CGFloat = 30

    private var pressLocation: CGPoint?
    public private(set) var isDragging = false
    private var hoveringHotZone = false

    public init() {}

    /// 按下鼠标，记录起点。
    public mutating func mouseDown(at location: CGPoint) {
        pressLocation = location
    }

    /// 拖拽移动。返回 true 表示刚跨过阈值、应显示面板（仅状态切换的那次返回 true）。
    @discardableResult
    public mutating func mouseDragged(to location: CGPoint) -> Bool {
        guard let start = pressLocation else { return false }
        let dx = location.x - start.x
        let dy = location.y - start.y
        let distance = sqrt(dx * dx + dy * dy)
        guard distance >= Self.dragThreshold else { return false }
        if isDragging { return false }
        isDragging = true
        return true
    }

    /// 松开鼠标，结束拖拽判定。
    public mutating func mouseUp() {
        pressLocation = nil
        isDragging = false
    }

    /// 热区 hover 状态切换。返回 true 表示状态发生变化（进入或离开）。
    @discardableResult
    public mutating func hotZoneHoverChanged(inside: Bool) -> Bool {
        guard inside != hoveringHotZone else { return false }
        hoveringHotZone = inside
        return true
    }

    /// 当前是否处于热区内。
    public var isInHotZone: Bool { hoveringHotZone }

    /// 重置全部状态。
    public mutating func reset() {
        pressLocation = nil
        isDragging = false
        hoveringHotZone = false
    }
}
