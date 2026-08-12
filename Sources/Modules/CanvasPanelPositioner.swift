import CoreGraphics

/// 画布子面板定位：基于工具栏窗口 frame 计算子面板位置，
/// 确保子面板在工具栏下方且不重叠，下方放不下时回退到上方。
public enum CanvasPanelPositioner {

    /// 计算子面板左下角屏幕坐标。
    /// - Parameters:
    ///   - toolbarFrame: 工具栏窗口在屏幕上的 frame
    ///   - panelSize: 子面板尺寸
    ///   - screenFrame: 屏幕边界
    ///   - gap: 子面板与工具栏的间距
    /// - Returns: 子面板左下角坐标
    public static func position(
        toolbarFrame: CGRect,
        panelSize: CGSize,
        screenFrame: CGRect,
        gap: CGFloat = 8
    ) -> CGPoint {
        let belowY = toolbarFrame.minY - panelSize.height - gap
        let useBelow = belowY >= screenFrame.minY
        let y = useBelow ? belowY : toolbarFrame.maxY + gap

        var x = toolbarFrame.midX - panelSize.width / 2
        x = Swift.max(screenFrame.minX, Swift.min(x, screenFrame.maxX - panelSize.width))
        return CGPoint(x: x, y: y)
    }
}
