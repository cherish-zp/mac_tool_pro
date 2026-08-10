import CoreGraphics

/// 贴图定位器：将选区坐标（相对屏幕原点）转为绝对屏幕坐标。
/// 选区在覆盖层视图坐标系中，视图原点 = 屏幕原点，需加上屏幕偏移得到全局坐标。
/// 纯函数，便于单测。
public enum PinPositioner {
    /// 计算贴图窗口在屏幕上的绝对位置。
    /// - Parameters:
    ///   - selectionOrigin: 选区在覆盖层视图中的原点（相对屏幕原点）
    ///   - screenFrame: 选区所在屏幕的 frame（含 origin 偏移）
    /// - Returns: 贴图窗口左下角的绝对屏幕坐标
    public static func pinPoint(selectionOrigin: CGPoint, screenFrame: CGRect) -> CGPoint {
        CGPoint(x: screenFrame.origin.x + selectionOrigin.x,
                y: screenFrame.origin.y + selectionOrigin.y)
    }
}
