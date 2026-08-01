import CoreGraphics

/// 截图选区的几何计算工具：规范化拖拽矩形、夹取到屏幕边界、约束最小尺寸。
/// 纯函数，无副作用，便于单测。
public enum SelectionRect {
    /// 将任意方向的拖拽起止点规范为标准 CGRect（origin 在左上，width/height 为正）。
    public static func normalize(start: CGPoint, end: CGPoint) -> CGRect {
        let minX = Swift.min(start.x, end.x)
        let minY = Swift.min(start.y, end.y)
        let maxX = Swift.max(start.x, end.x)
        let maxY = Swift.max(start.y, end.y)
        return CGRect(x: minX, y: minY, width: maxX - minX, height: maxY - minY)
    }

    /// 将矩形夹取到 bounds 范围内，确保不超出屏幕边界。
    public static func clamp(_ rect: CGRect, to bounds: CGRect) -> CGRect {
        let originX = Swift.max(bounds.minX, Swift.min(rect.minX, bounds.maxX))
        let originY = Swift.max(bounds.minY, Swift.min(rect.minY, bounds.maxY))
        let maxX = Swift.max(bounds.minX, Swift.min(rect.maxX, bounds.maxX))
        let maxY = Swift.max(bounds.minY, Swift.min(rect.maxY, bounds.maxY))
        return CGRect(x: originX, y: originY, width: maxX - originX, height: maxY - originY)
    }

    /// 强制矩形至少达到 minimum 尺寸（不足时以 origin 为起点扩展）。
    public static func enforceMinimumSize(_ rect: CGRect, minimum: CGFloat) -> CGRect {
        let width = Swift.max(rect.width, minimum)
        let height = Swift.max(rect.height, minimum)
        return CGRect(x: rect.origin.x, y: rect.origin.y, width: width, height: height)
    }

    /// 判断矩形是否满足最小尺寸要求（宽高均 >= minimum）。
    public static func isValid(_ rect: CGRect, minimum: CGFloat) -> Bool {
        rect.width >= minimum && rect.height >= minimum
    }
}
