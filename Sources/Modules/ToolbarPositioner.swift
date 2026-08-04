import CoreGraphics

/// 工具条定位器：计算工具条在选区正上方的屏幕坐标位置。
/// 纯函数，无副作用，便于单测。
public enum ToolbarPositioner {
    /// 计算工具条原点（屏幕坐标）。
    /// - Parameters:
    ///   - rect: 选区矩形（视图坐标，原点 0,0 相对于屏幕左下角）
    ///   - toolbarSize: 工具条尺寸
    ///   - screenFrame: 当前屏幕在 NSScreen 坐标系中的 frame（含 origin 偏移）
    ///   - margin: 工具条与选区的间距
    /// - Returns: 工具条左下角在屏幕坐标系中的位置
    public static func position(
        forSelection rect: CGRect,
        toolbarSize: CGSize,
        screenFrame: CGRect,
        margin: CGFloat = 8
    ) -> CGPoint {
        // 视图坐标 -> 屏幕坐标：加上屏幕 origin 偏移
        var originX = rect.midX - toolbarSize.width / 2 + screenFrame.origin.x
        var originY = rect.maxY + margin + screenFrame.origin.y

        // 上方放不下则放选区下方
        if originY + toolbarSize.height > screenFrame.maxY {
            originY = rect.minY - toolbarSize.height - margin + screenFrame.origin.y
        }

        // 水平/垂直夹取到屏幕边界内
        originX = Swift.max(screenFrame.minX, Swift.min(originX, screenFrame.maxX - toolbarSize.width))
        originY = Swift.max(screenFrame.minY, Swift.min(originY, screenFrame.maxY - toolbarSize.height))
        return CGPoint(x: originX, y: originY)
    }
}
