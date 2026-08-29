import CoreGraphics

/// 贴图等比例缩放器：计算缩放后的尺寸和窗口位置，保持宽高比和中心点。
/// 纯函数，便于单测。
public enum PinScaler {
    /// 最小缩放倍数。
    public static let minScale: CGFloat = 0.1
    /// 最大缩放倍数。
    public static let maxScale: CGFloat = 5.0

    /// 将缩放因子限制在 [minScale, maxScale] 范围内。
    public static func clampedScaleFactor(_ factor: CGFloat) -> CGFloat {
        Swift.max(minScale, Swift.min(maxScale, factor))
    }

    /// 根据缩放因子计算等比例缩放后的尺寸（自动限制范围）。
    public static func scaledSize(original: CGSize, scaleFactor: CGFloat) -> CGSize {
        let clamped = clampedScaleFactor(scaleFactor)
        return CGSize(width: original.width * clamped, height: original.height * clamped)
    }

    /// 计算缩放后的窗口 frame，保持原 frame 的中心点不变。
    public static func scaledFrame(originalFrame: CGRect, newSize: CGSize) -> CGRect {
        let center = CGPoint(x: originalFrame.midX, y: originalFrame.midY)
        return CGRect(x: center.x - newSize.width / 2,
                      y: center.y - newSize.height / 2,
                      width: newSize.width,
                      height: newSize.height)
    }

    // MARK: - 关闭按钮等比例缩放

    /// 关闭按钮原始尺寸（点）。
    public static let originalButtonSize: CGFloat = 22
    /// 关闭按钮原始边距（点）。
    public static let originalMargin: CGFloat = 4
    /// 关闭按钮最小尺寸（点），防止过小无法点击。
    public static let minButtonSize: CGFloat = 14
    /// 关闭按钮最大尺寸（点），防止过大遮挡图片。
    public static let maxButtonSize: CGFloat = 60

    /// 根据缩放因子计算关闭按钮尺寸（限制在 min/max 范围内）。
    public static func scaledButtonSize(scaleFactor: CGFloat) -> CGFloat {
        let raw = originalButtonSize * scaleFactor
        return Swift.max(minButtonSize, Swift.min(maxButtonSize, raw))
    }

    /// 计算关闭按钮在视图中的 frame（左上角，等比例缩放）。
    /// 视图 isFlipped=false（原点左下），左上角 = (margin*s, height - margin*s - size)。
    public static func scaledButtonFrame(viewBounds: CGRect, scaleFactor: CGFloat) -> CGRect {
        let size = scaledButtonSize(scaleFactor: scaleFactor)
        let margin = originalMargin * scaleFactor
        return CGRect(x: margin,
                      y: viewBounds.height - margin - size,
                      width: size, height: size)
    }

    // MARK: - 悬停浮现按钮（topBar 模式，尺寸减半）

    /// 悬停浮现按钮原始尺寸（点），为常规关闭按钮（22）的一半。
    public static let originalRevealButtonSize: CGFloat = 11
    /// 悬停浮现按钮最小尺寸（点），防止过小无法点击。
    public static let minRevealButtonSize: CGFloat = 8
    /// 悬停浮现按钮最大尺寸（点），防止过大遮挡图片。
    public static let maxRevealButtonSize: CGFloat = 30

    /// 根据缩放因子计算悬停浮现按钮尺寸（限制在 min/max 范围内）。
    public static func scaledRevealButtonSize(scaleFactor: CGFloat) -> CGFloat {
        let raw = originalRevealButtonSize * scaleFactor
        return Swift.max(minRevealButtonSize, Swift.min(maxRevealButtonSize, raw))
    }

    /// 计算悬停浮现按钮在视图中的 frame（左上角，等比例缩放，边距与常规按钮一致）。
    /// 视图 isFlipped=false（原点左下），左上角 = (margin*s, height - margin*s - size)。
    public static func scaledRevealButtonFrame(viewBounds: CGRect, scaleFactor: CGFloat) -> CGRect {
        let size = scaledRevealButtonSize(scaleFactor: scaleFactor)
        let margin = originalMargin * scaleFactor
        return CGRect(x: margin,
                      y: viewBounds.height - margin - size,
                      width: size, height: size)
    }
}
