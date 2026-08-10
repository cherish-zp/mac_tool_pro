import CoreGraphics

/// 画笔路径构建器：管理自由绘制路径的点序列，支持最小距离过滤避免点过密。
/// 鼠标拖拽时高频产生事件，过密的点浪费存储且无视觉收益，因此过滤近距离点。
struct PenPathBuilder {
    /// 最小点间距的平方（小于此距离的点被忽略），约 2pt。
    static let minDistanceSquared: CGFloat = 4

    /// 向路径添加新点，距离上一点太近则忽略。返回是否实际添加。
    @discardableResult
    static func append(_ point: CGPoint, to points: inout [CGPoint]) -> Bool {
        if let last = points.last {
            let dx = point.x - last.x
            let dy = point.y - last.y
            if dx * dx + dy * dy < minDistanceSquared { return false }
        }
        points.append(point)
        return true
    }
}
