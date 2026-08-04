import CoreGraphics

/// 窗口信息（从 CGWindowListCopyWindowInfo 提取的关键字段）。
public struct WindowInfo: Equatable {
    public let bounds: CGRect
    public let layer: Int
    public let ownerPid: Int32
    public let windowId: Int

    public init(bounds: CGRect, layer: Int, ownerPid: Int32, windowId: Int) {
        self.bounds = bounds
        self.layer = layer
        self.ownerPid = ownerPid
        self.windowId = windowId
    }
}

/// 窗口检测器：从窗口列表中找到鼠标下最顶层的普通窗口。
/// 纯函数，无副作用，便于单测。
public enum WindowDetector {
    /// 找到包含指定点的最顶层普通窗口（layer=0），排除指定 PID 的窗口。
    /// 窗口列表应按 z-order 排列（最顶层在前）。
    public static func topmostWindow(
        at point: CGPoint,
        in windows: [WindowInfo],
        excludingPids: [Int32] = []
    ) -> WindowInfo? {
        let excluded = Set(excludingPids)
        return windows.first { window in
            window.layer == 0 &&
            !excluded.contains(window.ownerPid) &&
            window.bounds.contains(point)
        }
    }
}

/// 屏幕坐标转换器：将 CG 窗口坐标（原点左上）转换为视图坐标（原点左下）。
public enum ScreenCoordinateConverter {
    /// 将 CG 坐标系的矩形转换为视图坐标系（NSScreen 底左原点，减去屏幕偏移）。
    /// - Parameters:
    ///   - cgRect: CG 坐标系的窗口矩形（原点在主屏左上角）
    ///   - screenFrame: 当前屏幕在 NSScreen 坐标系中的 frame
    ///   - primaryScreenHeight: 主屏高度（用于 y 轴翻转）
    public static func cgRectToViewRect(
        _ cgRect: CGRect,
        screenFrame: CGRect,
        primaryScreenHeight: CGFloat
    ) -> CGRect {
        let viewY = primaryScreenHeight - cgRect.maxY - screenFrame.origin.y
        let viewX = cgRect.origin.x - screenFrame.origin.x
        return CGRect(x: viewX, y: viewY, width: cgRect.width, height: cgRect.height)
    }
}
