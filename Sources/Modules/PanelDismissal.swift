import CoreGraphics

/// 截图子面板（更多/画布/颜色）点击外部关闭的几何判定。
/// 纯函数，便于单测；副作用（事件监控、关窗）由调用方处理。
public enum PanelDismissal {

    /// 点击点是否应关闭已打开的子面板：点在所有面板之外且不在工具条内。
    /// - Parameters:
    ///   - click: 点击点的屏幕坐标
    ///   - panelFrames: 当前打开的所有子面板 frame（屏幕坐标）
    ///   - toolbarFrame: 工具条 frame（屏幕坐标）
    public static func shouldDismiss(click: CGPoint, panelFrames: [CGRect], toolbarFrame: CGRect) -> Bool {
        if containsPoint(click, frames: panelFrames) { return false }
        if containsPoint(click, frames: [toolbarFrame]) { return false }
        return true
    }

    /// 点是否落在任一 frame 内。
    public static func containsPoint(_ point: CGPoint, frames: [CGRect]) -> Bool {
        frames.contains { $0.contains(point) }
    }
}
